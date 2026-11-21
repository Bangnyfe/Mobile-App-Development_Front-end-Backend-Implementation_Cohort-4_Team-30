import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/pharmacy_invite.dart';

/// Reads `invites/{email}`. Missing fields get safe defaults, and any
/// status other than "pending" counts as no longer pending.
PharmacyInvite inviteFromFirestore(String email, Map<String, dynamic> data) {
  final createdAt = data['createdAt'];
  return PharmacyInvite(
    email: email,
    pharmacyId: data['pharmacyId'] as String? ?? '',
    pharmacyName: data['pharmacyName'] as String? ?? 'A pharmacy',
    invitedBy: data['invitedBy'] as String? ?? '',
    invitedByName: data['invitedByName'] as String?,
    status: data['status'] == InviteStatus.pending.name
        ? InviteStatus.pending
        : InviteStatus.accepted,
    createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
  );
}

/// The fields of a new invite. The Firestore rules check `role`,
/// `status` and `invitedBy`, so they must match exactly.
Map<String, Object> newInviteToFirestore({
  required String email,
  required String pharmacyId,
  required String pharmacyName,
  required String invitedBy,
  String? invitedByName,
}) => {
  'email': email,
  'pharmacyId': pharmacyId,
  'pharmacyName': pharmacyName,
  'role': 'pharmacist',
  'invitedBy': invitedBy,
  'invitedByName': ?invitedByName,
  'status': InviteStatus.pending.name,
  'createdAt': FieldValue.serverTimestamp(),
};
