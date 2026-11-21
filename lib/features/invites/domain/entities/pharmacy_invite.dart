import 'package:equatable/equatable.dart';

/// Where an invite stands. A revoked invite is deleted, so it has no
/// status of its own.
enum InviteStatus { pending, accepted }

/// An owner's invitation for someone to join their pharmacy as a
/// pharmacist, stored at `invites/{email}`.
///
/// Keyed by the invited email (lowercased), so the invited person's app can
/// find it straight after they sign in, without searching. The owner tells
/// them about it themselves (e.g. on WhatsApp); no email is sent.
class PharmacyInvite extends Equatable {
  const PharmacyInvite({
    required this.email,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.invitedBy,
    this.invitedByName,
    this.status = InviteStatus.pending,
    this.createdAt,
  });

  /// Lowercased, see [normalizeEmail]. Also the document ID.
  final String email;

  final String pharmacyId;

  /// Copied onto the invite so the invited person can see which pharmacy
  /// it is before they're allowed to read the pharmacy itself.
  final String pharmacyName;

  /// UID of the owner who sent it.
  final String invitedBy;
  final String? invitedByName;

  final InviteStatus status;

  /// Null until the server timestamp is written.
  final DateTime? createdAt;

  bool get isPending => status == InviteStatus.pending;

  /// Emails are compared without case or surrounding spaces, so
  /// "Eric@Gmail.com " and "eric@gmail.com" are the same invite.
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  @override
  List<Object?> get props => [
    email,
    pharmacyId,
    pharmacyName,
    invitedBy,
    invitedByName,
    status,
    createdAt,
  ];
}
