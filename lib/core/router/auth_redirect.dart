import '../../features/auth/presentation/auth_route_paths.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'route_paths.dart';

/// Every screen that belongs to signing in, as opposed to the app's tabs.
const _authScreens = {
  AuthRoutePaths.splash,
  AuthRoutePaths.login,
  AuthRoutePaths.register,
  AuthRoutePaths.forgotPassword,
  AuthRoutePaths.verifyEmail,
  AuthRoutePaths.pharmacySetup,
};

/// Where the router must send someone at [location] with this sign-in
/// [status], or null to let them stay.
///
/// Kept as a pure function so every rule is unit-tested without a router.
String? authRedirect({required AuthStatus status, required String location}) {
  String? goTo(String path) => location == path ? null : path;

  return switch (status) {
    // Firebase has not reported the saved session yet.
    AuthStatus.unknown => goTo(AuthRoutePaths.splash),
    // Signed out: Login, Register and Forgot password only.
    AuthStatus.unauthenticated =>
      AuthRoutePaths.signedOut.contains(location) ? null : AuthRoutePaths.login,
    AuthStatus.needsVerification => goTo(AuthRoutePaths.verifyEmail),
    AuthStatus.needsPharmacy => goTo(AuthRoutePaths.pharmacySetup),
    // Signed in: leave the auth screens, but never interrupt the app.
    AuthStatus.authenticated =>
      _authScreens.contains(location) ? RoutePaths.home : null,
  };
}
