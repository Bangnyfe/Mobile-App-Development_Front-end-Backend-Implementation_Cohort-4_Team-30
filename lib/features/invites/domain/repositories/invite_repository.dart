import '../entities/pharmacy_invite.dart';

/// Owners invite pharmacists by email; the invited person joins from the
/// "needs pharmacy" step after signing in. Every method throws
/// `InviteFailure` with a message to show.
abstract interface class InviteRepository {
  /// The pending invite for [email], or null when there is none.
  Future<PharmacyInvite?> findPendingInvite(String email);

  /// Joins [invite]'s pharmacy as a pharmacist: creates `users/{uid}` and
  /// marks the invite accepted in one write, so neither can happen alone.
  Future<void> acceptInvite(
    PharmacyInvite invite, {
    required String uid,
    required String name,
  });

  /// Invites [email] to join [pharmacyId] as a pharmacist.
  Future<PharmacyInvite> sendInvite({
    required String email,
    required String pharmacyId,
    required String invitedBy,
    String? invitedByName,
  });

  /// Cancels a pending invite.
  Future<void> revokeInvite(String email);

  /// The pharmacy's pending invites, oldest first, updated live.
  Stream<List<PharmacyInvite>> watchPendingInvites(String pharmacyId);
}
