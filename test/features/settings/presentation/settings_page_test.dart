import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';

import '../settings_test_helpers.dart';

void main() {
  group('pharmacy', () {
    testWidgets('shows the pharmacy, who is signed in and the counts', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(find.text('Amani Pharmacy'), findsOneWidget);
      expect(find.text('Nyarugenge, Kigali'), findsOneWidget);
      expect(find.text('Signed in as Aline · Owner'), findsOneWidget);
      expect(find.text('Pharmacy profile'), findsOneWidget);
      expect(find.text('3 people'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
    });

    testWidgets('hides Staff and users from pharmacists', (tester) async {
      await pumpSettings(
        tester,
        accountRepository: TestAccountRepository(
          account: await pharmacistAccount(),
        ),
      );

      expect(find.text('Signed in as Eric · Pharmacist'), findsOneWidget);
      expect(find.text('Staff and users'), findsNothing);
      expect(find.text('Product categories'), findsOneWidget);
    });

    testWidgets('offers a retry when the pharmacy fails to load', (
      tester,
    ) async {
      final repository = TestAccountRepository(fail: true);
      await pumpSettings(tester, accountRepository: repository);

      expect(find.text("Couldn't load your pharmacy details."), findsOneWidget);
      // The alerts still work without the account.
      expect(find.text('20 units'), findsOneWidget);

      repository.fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Amani Pharmacy'), findsOneWidget);
    });
  });

  group('alerts', () {
    testWidgets('shows the defaults', (tester) async {
      await pumpSettings(tester);

      expect(find.text('20 units'), findsOneWidget);
      expect(find.text('90 days'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('edits the low stock threshold and saves it', (tester) async {
      final prefs = await pumpSettings(tester);

      await scrollToAndTap(tester, find.text('Low stock threshold'));
      await tester.enterText(find.byType(TextField), '35');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('35 units'), findsOneWidget);
      expect(
        prefs.getInt(SharedPrefsSettingsRepository.lowStockThresholdKey),
        35,
      );
    });

    testWidgets('keeps the dialog open for an out-of-range number', (
      tester,
    ) async {
      final prefs = await pumpSettings(tester);

      await scrollToAndTap(tester, find.text('Low stock threshold'));
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a number from 1 to 1000.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        prefs.getInt(SharedPrefsSettingsRepository.lowStockThresholdKey),
        isNull,
      );
    });

    testWidgets('cancel leaves the value unchanged', (tester) async {
      await pumpSettings(tester);

      await scrollToAndTap(tester, find.text('Expiry alert period'));
      await tester.enterText(find.byType(TextField), '30');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('90 days'), findsOneWidget);
    });

    testWidgets('edits the expiry alert period and saves it', (tester) async {
      final prefs = await pumpSettings(tester);

      await scrollToAndTap(tester, find.text('Expiry alert period'));
      await tester.enterText(find.byType(TextField), '366');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a number from 1 to 365.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '30');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('30 days'), findsOneWidget);
      expect(
        prefs.getInt(SharedPrefsSettingsRepository.expiryAlertDaysKey),
        30,
      );
    });

    testWidgets('tapping the push notifications row turns them off', (
      tester,
    ) async {
      final prefs = await pumpSettings(tester);

      await scrollToAndTap(tester, find.text('Push notifications'));

      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(
        prefs.getBool(SharedPrefsSettingsRepository.pushNotificationsKey),
        isFalse,
      );
    });
  });

  group('log out', () {
    testWidgets('asks first and does nothing on cancel', (tester) async {
      final repository = TestAccountRepository();
      await pumpSettings(tester, accountRepository: repository);

      await scrollToAndTap(tester, find.text('Log out'));
      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsNothing);
      expect(repository.signOutCount, 0);
    });

    testWidgets('signs out once confirmed', (tester) async {
      final repository = TestAccountRepository();
      await pumpSettings(tester, accountRepository: repository);

      await scrollToAndTap(tester, find.text('Log out'));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Log out'),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.signOutCount, 1);
    });
  });

  testWidgets('fits in landscape without overflowing', (tester) async {
    await pumpSettings(tester, physicalSize: const Size(2400, 1080));

    await scrollToAndTap(tester, find.text('Log out'));

    expect(tester.takeException(), isNull);
    expect(find.text('Log out?'), findsOneWidget);
  });
}
