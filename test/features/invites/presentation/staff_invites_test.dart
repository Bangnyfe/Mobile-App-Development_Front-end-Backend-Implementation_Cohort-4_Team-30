import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/features/invites/data/fake_invite_repository.dart';
import 'package:team30_app/features/invites/domain/entities/pharmacy_invite.dart';
import 'package:team30_app/features/invites/domain/invite_failure.dart';
import 'package:team30_app/features/invites/presentation/cubit/pharmacy_invites_cubit.dart';
import 'package:team30_app/features/settings/presentation/cubit/account_cubit.dart';
import 'package:team30_app/features/settings/presentation/pages/staff_page.dart';

import '../../settings/settings_test_helpers.dart';

final _invitedAt = DateTime(2026, 11, 20, 9);

/// Staff page for a signed-in owner, with [repository]'s invites.
Future<void> pumpStaff(
  WidgetTester tester,
  FakeInviteRepository repository, {
  Size physicalSize = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AccountCubit(TestAccountRepository())..load(),
          ),
          BlocProvider(
            create: (_) => PharmacyInvitesCubit(
              inviteRepository: repository,
              pharmacyId: 'p1',
              ownerUid: 'owner-1',
              ownerName: 'Aline',
            )..start(),
          ),
        ],
        child: const StaffPage(canInvite: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FakeInviteRepository repositoryWith(List<PharmacyInvite> invites) =>
    FakeInviteRepository(
      invites: invites,
      pharmacyNames: const {'p1': 'Amani Pharmacy'},
      clock: () => _invitedAt,
    );

Future<void> openDialogAndSend(WidgetTester tester, String email) async {
  await scrollToAndTap(tester, find.text('Invite pharmacist'));
  await tester.enterText(find.byType(TextFormField), email);
  await tester.tap(find.text('Send invite'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without pending invites, shows only the Invite button', (
    tester,
  ) async {
    await pumpStaff(tester, repositoryWith(const []));

    expect(find.text('PENDING INVITES'), findsNothing);
    expect(find.text('Invite pharmacist'), findsOneWidget);
  });

  testWidgets('lists pending invites with the date sent', (tester) async {
    await pumpStaff(
      tester,
      repositoryWith([
        PharmacyInvite(
          email: 'grace@gmail.com',
          pharmacyId: 'p1',
          pharmacyName: 'Amani Pharmacy',
          invitedBy: 'owner-1',
          createdAt: _invitedAt,
        ),
      ]),
    );

    await tester.scrollUntilVisible(find.text('grace@gmail.com'), 100);
    expect(find.text('PENDING INVITES'), findsOneWidget);
    expect(find.text('Pharmacist · invited 20 Nov 2026'), findsOneWidget);
  });

  testWidgets('the dialog checks the email before sending', (tester) async {
    final repository = repositoryWith(const []);
    await pumpStaff(tester, repository);

    await openDialogAndSend(tester, 'not-an-email');

    expect(
      find.text('Enter a valid email address, like name@pharmacy.rw.'),
      findsOneWidget,
    );
    expect(await repository.findPendingInvite('not-an-email'), isNull);
  });

  testWidgets('sending an invite lists it and confirms', (tester) async {
    await pumpStaff(tester, repositoryWith(const []));

    await openDialogAndSend(tester, 'Eric@Gmail.com');

    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text(
        'Invite sent. Tell Eric@Gmail.com to sign in with this email to join.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('eric@gmail.com'), 100);
    expect(find.text('eric@gmail.com'), findsOneWidget);
  });

  testWidgets('a refused invite keeps the dialog open with the reason', (
    tester,
  ) async {
    await pumpStaff(
      tester,
      repositoryWith(const [
        PharmacyInvite(
          email: 'eric@gmail.com',
          pharmacyId: 'p2',
          pharmacyName: 'Kacyiru Pharmacy',
          invitedBy: 'owner-2',
        ),
      ]),
    );

    await openDialogAndSend(tester, 'eric@gmail.com');

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(InviteFailure.invitedElsewhere), findsOneWidget);
  });

  testWidgets('revoking asks first, then removes the invite', (tester) async {
    final repository = repositoryWith([
      PharmacyInvite(
        email: 'grace@gmail.com',
        pharmacyId: 'p1',
        pharmacyName: 'Amani Pharmacy',
        invitedBy: 'owner-1',
        createdAt: _invitedAt,
      ),
    ]);
    await pumpStaff(tester, repository);

    await scrollToAndTap(tester, find.text('Revoke'));
    expect(find.text('Revoke invite?'), findsOneWidget);

    // Cancelling keeps it.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('grace@gmail.com'), findsOneWidget);

    await scrollToAndTap(tester, find.text('Revoke'));
    await tester.tap(find.widgetWithText(FilledButton, 'Revoke'));
    await tester.pumpAndSettle();

    expect(find.text('Invite for grace@gmail.com revoked.'), findsOneWidget);
    expect(find.text('PENDING INVITES'), findsNothing);
    expect(await repository.findPendingInvite('grace@gmail.com'), isNull);
  });

  testWidgets('without canInvite there is no Invite button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => AccountCubit(TestAccountRepository())..load(),
          child: const StaffPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aline Uwase'), findsOneWidget);
    expect(find.text('Invite pharmacist'), findsNothing);
  });

  testWidgets('fits in landscape without overflowing', (tester) async {
    await pumpStaff(
      tester,
      repositoryWith([
        PharmacyInvite(
          email: 'a-very-long-email-address-for-testing@amanipharmacy.rw',
          pharmacyId: 'p1',
          pharmacyName: 'Amani Pharmacy',
          invitedBy: 'owner-1',
          createdAt: _invitedAt,
        ),
      ]),
      physicalSize: const Size(2400, 1080),
    );

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Invite pharmacist'), 100);
    expect(find.text('Invite pharmacist'), findsOneWidget);
  });
}
