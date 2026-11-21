/// A failed invite action, with a message that can be shown as it is.
class InviteFailure implements Exception {
  const InviteFailure(this.message);

  final String message;

  static const alreadyInvited =
      'You have already invited this email. It is listed under pending '
      'invites.';
  static const invitedElsewhere =
      'This email already has a pending invite from another pharmacy.';
  static const noLongerAvailable =
      'This invite is no longer available. Ask your pharmacy owner to '
      'invite you again.';
  static const generic =
      'Something went wrong. Check your connection and try again.';

  @override
  String toString() => 'InviteFailure: $message';
}
