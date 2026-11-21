part of 'pharmacy_choice_cubit.dart';

enum PharmacyChoiceStatus {
  /// Checking for an invite and remembered pharmacy details.
  loading,

  /// Showing the choices: Join (when invited) and Create.
  ready,

  /// Accepting the invite.
  joining,

  /// Joined. AuthBloc sees the new profile and the router opens Home, so
  /// the page only shows progress until then.
  joined,
}

class PharmacyChoiceState extends Equatable {
  const PharmacyChoiceState({
    this.status = PharmacyChoiceStatus.loading,
    this.invite,
    this.draft,
    this.inviteCheckFailed = false,
    this.message,
    this.messageCount = 0,
  });

  final PharmacyChoiceStatus status;

  /// The pending invite for the signed-in email, if any.
  final PharmacyInvite? invite;

  /// What was typed on Register, to pre-fill Create.
  final PharmacyDraft? draft;

  /// True when the invite couldn't be checked (e.g. offline), so the page
  /// can offer to check again instead of silently hiding Join.
  final bool inviteCheckFailed;

  /// A message to show once, e.g. why joining failed.
  final String? message;

  /// Goes up with every message, so the same message twice still shows.
  final int messageCount;

  bool get isBusy =>
      status == PharmacyChoiceStatus.joining ||
      status == PharmacyChoiceStatus.joined;

  PharmacyChoiceState copyWith({
    PharmacyChoiceStatus? status,
    PharmacyInvite? Function()? invite,
    PharmacyDraft? Function()? draft,
    bool? inviteCheckFailed,
    String? message,
  }) => PharmacyChoiceState(
    status: status ?? this.status,
    invite: invite != null ? invite() : this.invite,
    draft: draft != null ? draft() : this.draft,
    inviteCheckFailed: inviteCheckFailed ?? this.inviteCheckFailed,
    message: message,
    messageCount: message != null ? messageCount + 1 : messageCount,
  );

  @override
  List<Object?> get props => [
    status,
    invite,
    draft,
    inviteCheckFailed,
    message,
    messageCount,
  ];
}
