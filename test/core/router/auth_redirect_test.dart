import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/router/auth_redirect.dart';
import 'package:team30_app/core/router/route_paths.dart';
import 'package:team30_app/features/auth/presentation/auth_route_paths.dart';
import 'package:team30_app/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  String? redirect(AuthStatus status, String location) =>
      authRedirect(status: status, location: location);

  test('an unknown session waits on Splash', () {
    expect(
      redirect(AuthStatus.unknown, RoutePaths.home),
      AuthRoutePaths.splash,
    );
    expect(redirect(AuthStatus.unknown, AuthRoutePaths.splash), isNull);
  });

  test('a signed-out user can only reach the signed-out screens', () {
    expect(
      redirect(AuthStatus.unauthenticated, RoutePaths.settings),
      AuthRoutePaths.login,
    );
    expect(
      redirect(AuthStatus.unauthenticated, AuthRoutePaths.splash),
      AuthRoutePaths.login,
    );
    expect(
      redirect(AuthStatus.unauthenticated, AuthRoutePaths.verifyEmail),
      AuthRoutePaths.login,
    );
    for (final screen in AuthRoutePaths.signedOut) {
      expect(redirect(AuthStatus.unauthenticated, screen), isNull);
    }
  });

  test('an unverified user is kept on Verify email', () {
    expect(
      redirect(AuthStatus.needsVerification, RoutePaths.home),
      AuthRoutePaths.verifyEmail,
    );
    expect(
      redirect(AuthStatus.needsVerification, AuthRoutePaths.register),
      AuthRoutePaths.verifyEmail,
    );
    expect(
      redirect(AuthStatus.needsVerification, AuthRoutePaths.verifyEmail),
      isNull,
    );
  });

  test('a user without a pharmacy is kept on Pharmacy setup', () {
    expect(
      redirect(AuthStatus.needsPharmacy, AuthRoutePaths.login),
      AuthRoutePaths.pharmacySetup,
    );
    expect(
      redirect(AuthStatus.needsPharmacy, AuthRoutePaths.pharmacySetup),
      isNull,
    );
  });

  test('a signed-in user leaves the auth screens but is never interrupted', () {
    expect(
      redirect(AuthStatus.authenticated, AuthRoutePaths.login),
      RoutePaths.home,
    );
    expect(
      redirect(AuthStatus.authenticated, AuthRoutePaths.splash),
      RoutePaths.home,
    );
    expect(redirect(AuthStatus.authenticated, RoutePaths.home), isNull);
    expect(redirect(AuthStatus.authenticated, RoutePaths.staff), isNull);
  });
}
