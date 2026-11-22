import 'dart:async';

import '../domain/entities/pharmacy_invite.dart';
import '../domain/invite_failure.dart';
import '../domain/repositories/invite_repository.dart';

/// Keeps invites in memory, for tests and for running the app without
/// Firestore. Follows the same rules as `FirestoreInviteRepository`.
class FakeInviteRepository implements InviteRepository {
  FakeInviteRepository({
    List<PharmacyInvite> invites = const [],
    this._pharmacyNames = const {},
    DateTime Function()? clock,
  }) : _invites = {for (final invite in invites) invite.email: invite},
       _clock = clock ?? DateTime.now;

  final Map<String, PharmacyInvite> _invites;
  final Map<String, String> _pharmacyNames;
  final DateTime Function() _clock;
  final _changes = StreamController<void>.broadcast();

  /// Who joined which pharmacy, so tests can check [acceptInvite].
  final joined = <String, String>{};

  /// Set to make every call fail, e.g. to test error messages.
  bool fail = false;

  void _check() {
    if (fail) throw const InviteFailure(InviteFailure.generic);
  }

  @override
  Future<PharmacyInvite?> findPendingInvite(String email) async {
    _check();
    final invite = _invites[PharmacyInvite.normalizeEmail(email)];
    return invite != null && invite.isPending ? invite : null;
  }

  @override
  Future<void> acceptInvite(
    PharmacyInvite invite, {
    required String uid,
    required String name,
  }) async {
    _check();
    final current = _invites[invite.email];
    if (current == null ||
        !current.isPending ||
        current.pharmacyId != invite.pharmacyId) {
      throw const InviteFailure(InviteFailure.noLongerAvailable);
    }
    _invites[invite.email] = PharmacyInvite(
      email: current.email,
      pharmacyId: current.pharmacyId,
      pharmacyName: current.pharmacyName,
      invitedBy: current.invitedBy,
      invitedByName: current.invitedByName,
      status: InviteStatus.accepted,
      createdAt: current.createdAt,
    );
    joined[uid] = current.pharmacyId;
    _changes.add(null);
  }

  @override
  Future<PharmacyInvite> sendInvite({
    required String email,
    required String pharmacyId,
    required String invitedBy,
    String? invitedByName,
  }) async {
    _check();
    final key = PharmacyInvite.normalizeEmail(email);
    final existing = _invites[key];
    if (existing != null && existing.isPending) {
      throw InviteFailure(
        existing.pharmacyId == pharmacyId
            ? InviteFailure.alreadyInvited
            : InviteFailure.invitedElsewhere,
      );
    }
    final invite = PharmacyInvite(
      email: key,
      pharmacyId: pharmacyId,
      pharmacyName: _pharmacyNames[pharmacyId] ?? 'Your pharmacy',
      invitedBy: invitedBy,
      invitedByName: invitedByName,
      createdAt: _clock(),
    );
    _invites[key] = invite;
    _changes.add(null);
    return invite;
  }

  @override
  Future<void> revokeInvite(String email) async {
    _check();
    final key = PharmacyInvite.normalizeEmail(email);
    if (_invites[key]?.isPending ?? false) {
      _invites.remove(key);
      _changes.add(null);
    }
  }

  @override
  Stream<List<PharmacyInvite>> watchPendingInvites(String pharmacyId) {
    List<PharmacyInvite> pending() =>
        _invites.values
            .where((i) => i.pharmacyId == pharmacyId && i.isPending)
            .toList()
          ..sort(_oldestFirst);

    return Stream.multi((controller) {
      if (fail) {
        controller.addError(const InviteFailure(InviteFailure.generic));
        return;
      }
      controller.add(pending());
      final subscription = _changes.stream.listen(
        (_) => controller.add(pending()),
      );
      controller.onCancel = subscription.cancel;
    });
  }

  static int _oldestFirst(PharmacyInvite a, PharmacyInvite b) {
    final byDate = (a.createdAt ?? DateTime(0)).compareTo(
      b.createdAt ?? DateTime(0),
    );
    return byDate != 0 ? byDate : a.email.compareTo(b.email);
  }
}
