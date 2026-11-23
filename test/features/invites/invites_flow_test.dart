import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/domain/user_role.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/core/router/route_paths.dart';
import 'package:team30_app/features/auth/data/in_memory_pharmacy_draft_repository.dart';
import 'package:team30_app/features/auth/domain/entities/app_user.dart';
import 'package:team30_app/features/auth/domain/entities/pharmacy_draft.dart';
import 'package:team30_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team30_app/features/auth/presentation/pages/pharmacy_setup_page.dart';
import 'package:team30_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:team30_app/features/invites/data/fake_invite_repository.dart';
import 'package:team30_app/features/invites/domain/entities/pharmacy_invite.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';

import '../auth/presentation/auth_test_helpers.dart';

/// A verified pharmacist-to-be who signed up with email.
const _eric = AppUser(
  uid: 'u2',
  email: 'eric@gmail.com',
  name: 'Eric',
  emailVerified: true,
);

const _owner = AppUser(
  uid: 'owner-1',
  email: 'aline@amanipharmacy.rw',
  name: 'Aline',
  emailVerified: true,
  role: UserRole.owner,
  pharmacyId: 'p1',
);

const _invite = PharmacyInvite(
  email: 'eric@gmail.com',
  pharmacyId: 'p1',
  pharmacyName: 'Amani Pharmacy',
  invitedBy: 'owner-1',
  invitedByName: 'Aline',
);

void main() {
  late MockAuthBloc bloc;
  late StreamController<AuthState> authStates;
  late FakeInviteRepository invites;
  late InMemoryPharmacyDraftRepository drafts;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    bloc = MockAuthBloc();
    authStates = StreamController<AuthState>.broadcast();
    addTearDown(authStates.close);
    invites = FakeInviteRepository(
      invites: const [_invite],
      pharmacyNames: const {'p1': 'Amani Pharmacy'},
    );
    drafts = InMemoryPharmacyDraftRepository({
      'u2': const PharmacyDraft(
        name: 'Eric Pharmacy',
        district: 'Gasabo',
        city: 'Kigali',
      ),
    });
  });

  /// The whole app, routed by [bloc] starting at [initial]. Returns the
  /// router so tests can open a page directly.
  Future<GoRouter> pumpApp(WidgetTester tester, AuthState initial) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    whenListen(bloc, authStates.stream, initialState: initial);
    final router = createAppRouter(authBloc: bloc);
    await tester.pumpWidget(
      PharmacyApp(
        router: router,
        settingsRepository: SharedPrefsSettingsRepository(
          await SharedPreferences.getInstance(),
        ),
        authBloc: bloc,
        inviteRepository: invites,
        pharmacyDraftRepository: drafts,
      ),
    );
    await settle(tester);
    return router;
  }

  testWidgets('an invited user joins and lands on Home as a pharmacist', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AuthState(status: AuthStatus.needsPharmacy, user: _eric),
    );

    expect(find.byType(PharmacySetupPage), findsOneWidget);
    expect(find.text('You have been invited'), findsOneWidget);
    // Create is still offered, pre-filled from Register.
    expect(find.text('Eric Pharmacy'), findsOneWidget);

    await tapText(tester, 'Join Amani Pharmacy as a pharmacist');
    await settle(tester);
    expect(invites.joined, {'u2': 'p1'});

    // The new users/{uid} profile reaches AuthBloc, which signs them in.
    authStates.add(
      const AuthState(
        status: AuthStatus.authenticated,
        user: AppUser(
          uid: 'u2',
          email: 'eric@gmail.com',
          name: 'Eric',
          emailVerified: true,
          role: UserRole.pharmacist,
          pharmacyId: 'p1',
        ),
      ),
    );
    await settle(tester);

    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(await drafts.load('u2'), isNull);
  });

  testWidgets('without an invite, the pre-filled form creates a pharmacy', (
    tester,
  ) async {
    invites = FakeInviteRepository();
    await pumpApp(
      tester,
      const AuthState(status: AuthStatus.needsPharmacy, user: _eric),
    );

    expect(find.text('Set up your pharmacy'), findsOneWidget);
    expect(find.textContaining('Join'), findsNothing);

    await tapText(tester, 'Continue');

    verify(
      () => bloc.add(
        const AuthPharmacySetupSubmitted(
          pharmacyName: 'Eric Pharmacy',
          pharmacyDistrict: 'Gasabo',
          pharmacyCity: 'Kigali',
        ),
      ),
    ).called(1);
  });

  testWidgets('a signed-in owner can invite from Settings > Staff', (
    tester,
  ) async {
    invites = FakeInviteRepository(pharmacyNames: const {'p1': 'Amani'});
    final router = await pumpApp(
      tester,
      const AuthState(status: AuthStatus.authenticated, user: _owner),
    );

    router.go(RoutePaths.staff);
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Invite pharmacist'), 100);
    await tapText(tester, 'Invite pharmacist');
    await settle(tester);
    await tester.enterText(find.byType(TextFormField), 'grace@gmail.com');
    await tapText(tester, 'Send invite');
    await settle(tester);

    final invite = await invites.findPendingInvite('grace@gmail.com');
    expect(invite?.pharmacyId, 'p1');
    expect(invite?.invitedBy, 'owner-1');
    expect(invite?.invitedByName, 'Aline');
  });

  testWidgets('a signed-in pharmacist cannot invite', (tester) async {
    final router = await pumpApp(
      tester,
      const AuthState(
        status: AuthStatus.authenticated,
        user: AppUser(
          uid: 'u2',
          email: 'eric@gmail.com',
          name: 'Eric',
          emailVerified: true,
          role: UserRole.pharmacist,
          pharmacyId: 'p1',
        ),
      ),
    );

    router.go(RoutePaths.staff);
    await settle(tester);

    expect(find.text('Invite pharmacist'), findsNothing);
  });
}

/// Lets navigation and async work finish. A fixed time instead of
/// pumpAndSettle, because Splash and spinners animate forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}
