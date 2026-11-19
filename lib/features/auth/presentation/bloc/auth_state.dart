part of 'auth_bloc.dart';

/// Where the signed-in user belongs. The router reads this to decide
/// which screen to show.
enum AuthStatus {
  unknown,
  unauthenticated,

  /// Email/password account whose verification link has not been opened.
  needsVerification,

  /// Signed in but not linked to a pharmacy yet (first Google sign-in).
  needsPharmacy,
  authenticated;

  /// Verification is checked before the pharmacy on purpose: right after
  /// registration, Firebase reports the new user before the pharmacy
  /// document is written, and this order still sends them to Verify email.
  static AuthStatus fromUser(AppUser? user) {
    if (user == null) return unauthenticated;
    if (!user.emailVerified) return needsVerification;
    if (!user.hasPharmacy) return needsPharmacy;
    return authenticated;
  }
}

enum AuthAction {
  none,
  signIn,
  register,
  google,
  passwordReset,
  resendVerification,
  checkVerification,
  pharmacySetup,
  signOut,
}

enum ActionStatus { idle, inProgress, success, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.action = AuthAction.none,
    this.actionStatus = ActionStatus.idle,
    this.message,
  });

  final AuthStatus status;
  final AppUser? user;
  final AuthAction action;
  final ActionStatus actionStatus;

  final String? message;

  bool isBusy(AuthAction action) =>
      this.action == action && actionStatus == ActionStatus.inProgress;

  bool get isAnyBusy => actionStatus == ActionStatus.inProgress;

  AuthState withUser(AppUser? user) => AuthState(
    status: AuthStatus.fromUser(user),
    user: user,
    action: action,
    actionStatus: actionStatus,
    message: message,
  );

  AuthState withAction(
    AuthAction action,
    ActionStatus actionStatus, {
    String? message,
  }) => AuthState(
    status: status,
    user: user,
    action: action,
    actionStatus: actionStatus,
    message: message,
  );

  @override
  List<Object?> get props => [status, user, action, actionStatus, message];
}