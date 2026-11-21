import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/user_role.dart';
import '../domain/entities/pharmacy_invite.dart';
import '../domain/invite_failure.dart';
import '../domain/repositories/invite_repository.dart';
import 'invite_firestore_mapper.dart';

/// Invites in the top-level `invites` collection, one document per
/// invited email. `firestore.rules` decides who may read and write them.
class FirestoreInviteRepository implements InviteRepository {
  FirestoreInviteRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('invites');

  DocumentReference<Map<String, dynamic>> _invite(String email) =>
      _invites.doc(PharmacyInvite.normalizeEmail(email));

  @override
  Future<PharmacyInvite?> findPendingInvite(String email) => _guard(() async {
    final doc = await _invite(email).get();
    final data = doc.data();
    if (data == null) return null;
    final invite = inviteFromFirestore(doc.id, data);
    return invite.isPending ? invite : null;
  });

  @override
  Future<void> acceptInvite(
    PharmacyInvite invite, {
    required String uid,
    required String name,
  }) async {
    final batch = _firestore.batch()
      ..set(_firestore.collection('users').doc(uid), {
        'name': name,
        'email': invite.email,
        'role': UserRole.pharmacist.name,
        'pharmacyId': invite.pharmacyId,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(_invite(invite.email), {
        'status': InviteStatus.accepted.name,
        'acceptedBy': uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      // The rules only allow this while the invite is still pending, so a
      // refusal means it was revoked or already used.
      if (e.code == 'permission-denied' || e.code == 'not-found') {
        throw const InviteFailure(InviteFailure.noLongerAvailable);
      }
      throw const InviteFailure(InviteFailure.generic);
    }
  }

  @override
  Future<PharmacyInvite> sendInvite({
    required String email,
    required String pharmacyId,
    required String invitedBy,
    String? invitedByName,
  }) => _guard(() async {
    final key = PharmacyInvite.normalizeEmail(email);

    final DocumentSnapshot<Map<String, dynamic>> existing;
    try {
      existing = await _invite(key).get();
    } on FirebaseException catch (e) {
      // Owners can only read their own pharmacy's invites, so a refusal
      // means another pharmacy has invited this email.
      if (e.code == 'permission-denied') {
        throw const InviteFailure(InviteFailure.invitedElsewhere);
      }
      rethrow;
    }
    final existingData = existing.data();
    if (existingData != null) {
      final current = inviteFromFirestore(key, existingData);
      if (current.isPending) {
        throw InviteFailure(
          current.pharmacyId == pharmacyId
              ? InviteFailure.alreadyInvited
              : InviteFailure.invitedElsewhere,
        );
      }
    }

    final pharmacy = await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .get();
    final pharmacyName = pharmacy.data()?['name'] as String? ?? 'Your pharmacy';

    await _invite(key).set(
      newInviteToFirestore(
        email: key,
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
        invitedBy: invitedBy,
        invitedByName: invitedByName,
      ),
    );
    return PharmacyInvite(
      email: key,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      invitedBy: invitedBy,
      invitedByName: invitedByName,
    );
  });

  @override
  Future<void> revokeInvite(String email) =>
      _guard(() => _invite(email).delete());

  @override
  Stream<List<PharmacyInvite>> watchPendingInvites(String pharmacyId) {
    // Two equality filters need no composite index; sorted here instead
    // of with orderBy, which would.
    return _invites
        .where('pharmacyId', isEqualTo: pharmacyId)
        .where('status', isEqualTo: InviteStatus.pending.name)
        .snapshots()
        .map(
          (snapshot) =>
              [
                for (final doc in snapshot.docs)
                  inviteFromFirestore(doc.id, doc.data()),
              ]..sort(
                (a, b) => (a.createdAt ?? DateTime(9999)).compareTo(
                  b.createdAt ?? DateTime(9999),
                ),
              ),
        )
        .handleError((Object _) {
          throw const InviteFailure(InviteFailure.generic);
        });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on InviteFailure {
      rethrow;
    } on FirebaseException {
      throw const InviteFailure(InviteFailure.generic);
    }
  }
}
