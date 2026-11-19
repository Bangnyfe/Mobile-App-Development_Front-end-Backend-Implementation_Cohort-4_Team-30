import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/router/route_paths.dart';
import 'package:team30_app/features/settings/domain/entities/pharmacy_account.dart';
import 'package:team30_app/features/settings/presentation/pages/settings_page.dart';

import '../settings_test_helpers.dart';

void main() {
  for (final row in [
    'Pharmacy profile',
    'Staff and users',
    'Product categories',
  ]) {
    testWidgets('$row opens inside the Settings tab and back returns', (
      tester,
    ) async {
      await pumpSettings(tester);

      await scrollToAndTap(tester, find.text(row));

      expect(find.widgetWithText(AppBar, row), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });
  }

  testWidgets('Pharmacy profile shows the pharmacy details', (tester) async {
    await pumpSettings(tester, location: RoutePaths.pharmacyProfile);

    expect(find.text('Amani Pharmacy'), findsOneWidget);
    expect(find.text('Nyarugenge'), findsOneWidget);
    expect(find.text('Kigali'), findsOneWidget);
    expect(find.text('KN 4 Ave'), findsOneWidget);
    expect(find.text('+250 788 000 000'), findsOneWidget);
  });

  group('Staff and users', () {
    testWidgets('lists owners and pharmacists separately', (tester) async {
      await pumpSettings(tester, location: RoutePaths.staff);

      expect(find.text('OWNERS'), findsOneWidget);
      expect(find.text('PHARMACISTS'), findsOneWidget);
      expect(find.text('Aline Uwase'), findsOneWidget);
      expect(find.text('Eric Mugisha'), findsOneWidget);
      expect(find.text('Diane Ingabire'), findsOneWidget);
    });

    testWidgets('is blocked for pharmacists', (tester) async {
      await pumpSettings(
        tester,
        location: RoutePaths.staff,
        accountRepository: TestAccountRepository(
          account: await pharmacistAccount(),
        ),
      );

      expect(
        find.text('Only the pharmacy owner can view staff and users.'),
        findsOneWidget,
      );
      expect(find.text('Diane Ingabire'), findsNothing);
    });
  });

  group('Product categories', () {
    testWidgets('lists categories A to Z with product counts', (tester) async {
      final sample = await TestAccountRepository().load();
      await pumpSettings(
        tester,
        location: RoutePaths.categories,
        accountRepository: TestAccountRepository(
          account: PharmacyAccount(
            pharmacy: sample.pharmacy,
            user: sample.user,
            staff: sample.staff,
            categories: const [
              ProductCategory(id: 'c2', name: 'Vitamins', productCount: 1),
              ProductCategory(id: 'c1', name: 'Antibiotics', productCount: 52),
            ],
          ),
        ),
      );

      expect(find.text('2 CATEGORIES'), findsOneWidget);
      expect(find.text('52 products'), findsOneWidget);
      expect(find.text('1 product'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Antibiotics')).dy,
        lessThan(tester.getTopLeft(find.text('Vitamins')).dy),
      );
    });

    testWidgets('says so when there are none', (tester) async {
      final sample = await TestAccountRepository().load();
      await pumpSettings(
        tester,
        location: RoutePaths.categories,
        accountRepository: TestAccountRepository(
          account: PharmacyAccount(
            pharmacy: sample.pharmacy,
            user: sample.user,
            staff: sample.staff,
            categories: const [],
          ),
        ),
      );

      expect(find.text('No categories yet.'), findsOneWidget);
    });
  });

  testWidgets('a subpage offers a retry when loading fails', (tester) async {
    final repository = TestAccountRepository(fail: true);
    await pumpSettings(
      tester,
      location: RoutePaths.pharmacyProfile,
      accountRepository: repository,
    );

    expect(find.text("Couldn't load your pharmacy details."), findsOneWidget);

    repository.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('KN 4 Ave'), findsOneWidget);
  });
}
