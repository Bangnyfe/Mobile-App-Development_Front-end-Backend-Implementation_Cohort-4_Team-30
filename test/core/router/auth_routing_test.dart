import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/features/auth/domain/entities/app_user.dart';
import 'package:team30_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team30_app/features/auth/presentation/pages/login_page.dart';
import 'package:team30_app/features/auth/presentation/pages/pharmacy_setup_page.dart';
import 'package:team30_app/features/auth/presentation/pages/splash_page.dart';
import 'package:team30_app/features/auth/presentation/pages/verify_email_page.dart';
import 'package:team30_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';

import '../../features/auth/presentation/auth_test_helpers.dart';

const _owner = AppUser(
  uid: 'u1',
  email: 'aline@amanipharmacy.rw',
  name: 'Aline',
  emailVerified: true,
  role: UserRole.owner,
  pharmacyId: 'p1',
);

const _signedOut = AuthState(status: AuthStatus.unauthenticated);
const _signedIn = AuthState(status: AuthStatus.authenticated, user: _owner);

void main() {
  late MockAuthBloc bloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    bloc = MockAuthBloc();
  });

  /// Pumps the whole app, routed by [bloc], and lets it settle for a
  /// fixed time (Splash's progress bar never stops animating).
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      PharmacyApp(
        router: createAppRouter(authBloc: bloc),
        settingsRepository: SharedPrefsSettingsRepository(
          await SharedPreferences.getInstance(),
        ),
        authBloc: bloc,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('shows Splash until the session is known', (tester) async {
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(),
    );
    await pumpApp(tester);

    expect(find.byType(SplashPage), findsOneWidget);
  });

  testWidgets('a signed-out user lands on Login without the tabs', (
    tester,
  ) async {
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: _signedOut);
    await pumpApp(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('an unverified user opens Verify email', (tester) async {
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: AuthState(
        status: AuthStatus.needsVerification,
        user: _owner.copyWith(emailVerified: false),
      ),
    );
    await pumpApp(tester);

    expect(find.byType(VerifyEmailPage), findsOneWidget);
  });

  testWidgets('a Google user without a pharmacy opens Pharmacy setup', (
    tester,
  ) async {
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.needsPharmacy,
        user: AppUser(
          uid: 'u2',
          email: 'eric@gmail.com',
          name: 'Eric',
          emailVerified: true,
        ),
      ),
    );
    await pumpApp(tester);

    expect(find.byType(PharmacySetupPage), findsOneWidget);
  });

  testWidgets('signing in moves from Login to Home', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable(const [_signedIn]),
      initialState: _signedOut,
    );
    await pumpApp(tester);

    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('signing out returns to Login', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable(const [_signedOut]),
      initialState: _signedIn,
    );
    await pumpApp(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
