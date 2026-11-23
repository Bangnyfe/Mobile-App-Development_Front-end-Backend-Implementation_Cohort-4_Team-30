/// Paths of the screens shown before the user reaches the app's tabs.
abstract final class AuthRoutePaths {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const pharmacySetup = '/pharmacy-setup';

  /// Screens a signed-out user may open.
  static const signedOut = {login, register, forgotPassword};
}
