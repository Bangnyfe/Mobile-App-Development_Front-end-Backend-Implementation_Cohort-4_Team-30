import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/core/widgets/feature_placeholder_page.dart';
import 'package:team30_app/features/reports/presentation/pages/reports_hub_page.dart';
import 'package:team30_app/features/sales/data/fake_sales_repository.dart';
import 'package:team30_app/features/sales/presentation/pages/sale_details_page.dart';
import 'package:team30_app/features/sales/presentation/pages/sales_history_page.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';

/// Index of the Reports tab in the bottom bar.
const _reportsTab = 3;

/// The whole app on a phone-sized screen, opened on the Reports tab.
Future<void> pumpReportsTab(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    PharmacyApp(
      router: createAppRouter(),
      settingsRepository: SharedPrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      ),
      salesRepository: FakeSalesRepository(
        clock: () => DateTime(2026, 11, 19, 15),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Reports'),
    ),
  );
  await tester.pumpAndSettle();
}

int selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Sales history and a sale open inside the Reports tab', (
    tester,
  ) async {
    await pumpReportsTab(tester);

    await tapAndSettle(tester, find.text('Sales history'));
    expect(find.byType(SalesHistoryPage), findsOneWidget);
    expect(selectedTab(tester), _reportsTab);

    await tapAndSettle(tester, find.text('Sale #0141'));
    expect(find.byType(SaleDetailsPage), findsOneWidget);
    expect(find.text('ORS sachets'), findsOneWidget);
    // Still on Reports: the details didn't jump to the Home tab.
    expect(selectedTab(tester), _reportsTab);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SalesHistoryPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ReportsHubPage), findsOneWidget);
  });

  for (final title in ['Inventory report', 'Expiry & waste report']) {
    testWidgets('$title opens its placeholder until Brian\'s is merged', (
      tester,
    ) async {
      await pumpReportsTab(tester);

      await tapAndSettle(tester, find.text(title));

      expect(
        tester
            .widget<FeaturePlaceholderPage>(find.byType(FeaturePlaceholderPage))
            .title,
        title,
      );
      expect(selectedTab(tester), _reportsTab);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ReportsHubPage), findsOneWidget);
    });
  }

  testWidgets('Sales history opened from Home still opens sales in Home', (
    tester,
  ) async {
    await pumpReportsTab(tester);
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
    );

    await tester.scrollUntilVisible(find.text('See all'), 200);
    await tapAndSettle(tester, find.text('See all'));
    await tapAndSettle(tester, find.text('Sale #0141'));

    expect(find.byType(SaleDetailsPage), findsOneWidget);
    expect(selectedTab(tester), 0);
  });
}
