import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/auth/data/in_memory_pharmacy_draft_repository.dart';
import 'package:team30_app/features/auth/domain/entities/app_user.dart';
import 'package:team30_app/features/auth/domain/entities/pharmacy_draft.dart';
import 'package:team30_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team30_app/features/auth/presentation/pages/pharmacy_setup_page.dart';
import 'package:team30_app/features/invites/data/fake_invite_repository.dart';
import 'package:team30_app/features/invites/domain/entities/pharmacy_invite.dart';
import 'package:team30_app/features/invites/domain/invite_failure.dart';
import 'package:team30_app/features/invites/presentation/cubit/pharmacy_choice_cubit.dart';

import 'auth_test_helpers.dart';

const _googleUser = AppUser(
  uid: 'u2',
  email: 'eric@gmail.com',
  name: 'Eric',
  emailVerified: true,
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
  late FakeInviteRepository invites;
  late InMemoryPharmacyDraftRepository drafts;

  setUpAll(() => registerFallbackValue(const AuthStarted()));

  setUp(() {
    bloc = MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.needsPharmacy,
        user: _googleUser,
      ),
    );
    invites = FakeInviteRepository();
    drafts = InMemoryPharmacyDraftRepository();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Size physicalSize = const Size(1080, 2400),
  }) async {
    await pumpAuthPage(
      tester,
      bloc: bloc,
      page: BlocProvider(
        create: (_) => PharmacyChoiceCubit(
          inviteRepository: invites,
          draftRepository: drafts,
          user: _googleUser,
        )..load(),
        child: const PharmacySetupPage(),
      ),
    );
    tester.view.physicalSize = physicalSize;
    await tester.pumpAndSettle();
  }

  group('without an invite', () {
    testWidgets('shows the signed-in account and requires both fields', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(find.textContaining('eric@gmail.com'), findsOneWidget);
      expect(find.text('Set up your pharmacy'), findsOneWidget);
      expect(find.textContaining('Join'), findsNothing);

      await tapText(tester, 'Continue');

      expect(find.text('Enter the pharmacy name.'), findsOneWidget);
      expect(find.text('Enter the district.'), findsOneWidget);
      expect(find.text('Enter the city.'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('a valid form creates the pharmacy', (tester) async {
      await pumpPage(tester);
      await fillFields(tester, [' Kacyiru Pharmacy ', 'Gasabo ', ' Kigali']);
      await tapText(tester, 'Continue');

      verify(
        () => bloc.add(
          const AuthPharmacySetupSubmitted(
            pharmacyName: 'Kacyiru Pharmacy',
            pharmacyDistrict: 'Gasabo',
            pharmacyCity: 'Kigali',
          ),
        ),
      ).called(1);
    });

    testWidgets('is pre-filled with the details typed on Register', (
      tester,
    ) async {
      drafts = InMemoryPharmacyDraftRepository({
        'u2': const PharmacyDraft(
          name: 'Eric Pharmacy',
          district: 'Rubavu',
          city: 'Gisenyi',
        ),
      });
      await pumpPage(tester);

      expect(find.text('Eric Pharmacy'), findsOneWidget);
      expect(find.text('Rubavu'), findsOneWidget);
      expect(find.text('Gisenyi'), findsOneWidget);

      await tapText(tester, 'Continue');
      verify(
        () => bloc.add(
          const AuthPharmacySetupSubmitted(
            pharmacyName: 'Eric Pharmacy',
            pharmacyDistrict: 'Rubavu',
            pharmacyCity: 'Gisenyi',
          ),
        ),
      ).called(1);
    });

    testWidgets('offers to check again when the invite check failed', (
      tester,
    ) async {
      invites = FakeInviteRepository(invites: const [_invite])..fail = true;
      await pumpPage(tester);

      expect(find.textContaining("couldn't check for an invite"), findsOne);
      expect(find.textContaining('Join'), findsNothing);

      invites.fail = false;
      await tapText(tester, 'Check again');
      await tester.pumpAndSettle();

      expect(find.text('Join Amani Pharmacy as a pharmacist'), findsOneWidget);
    });
  });

  group('with an invite', () {
    setUp(() => invites = FakeInviteRepository(invites: const [_invite]));

    testWidgets('offers both Join and Create', (tester) async {
      await pumpPage(tester);

      expect(find.text('You have been invited'), findsOneWidget);
      expect(find.text('Invited by Aline · Role: Pharmacist'), findsOneWidget);
      expect(find.text('Join Amani Pharmacy as a pharmacist'), findsOneWidget);
      expect(find.text('Create my own pharmacy'), findsOneWidget);
      expect(find.text('Create my pharmacy'), findsOneWidget);
    });

    testWidgets('Join accepts the invite and shows progress', (tester) async {
      await pumpPage(tester);

      await tapText(tester, 'Join Amani Pharmacy as a pharmacist');
      await tester.pump();

      expect(invites.joined, {'u2': 'p1'});
      // Waits for AuthBloc to see the new profile and leave the page.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('a revoked invite shows why and leaves only Create', (
      tester,
    ) async {
      await pumpPage(tester);
      await invites.revokeInvite('eric@gmail.com');

      await tapText(tester, 'Join Amani Pharmacy as a pharmacist');
      await tester.pumpAndSettle();

      expect(find.text(InviteFailure.noLongerAvailable), findsOneWidget);
      expect(find.text('Set up your pharmacy'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Create still works instead of joining', (tester) async {
      await pumpPage(tester);
      await fillFields(tester, ['Eric Pharmacy', 'Gasabo', 'Kigali']);

      await tapText(tester, 'Create my pharmacy');

      verify(
        () => bloc.add(
          const AuthPharmacySetupSubmitted(
            pharmacyName: 'Eric Pharmacy',
            pharmacyDistrict: 'Gasabo',
            pharmacyCity: 'Kigali',
          ),
        ),
      ).called(1);
      expect(invites.joined, isEmpty);
    });

    testWidgets('fits in landscape without overflowing', (tester) async {
      await pumpPage(tester, physicalSize: const Size(2400, 1080));

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Use another account'));
      expect(find.text('Use another account'), findsOneWidget);
    });
  });
}
