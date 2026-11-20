import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:team30_app/features/sales/presentation/pages/sale_details_page.dart';
import 'package:team30_app/features/sales/presentation/pages/sales_history_page.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';

/// The whole app on a phone-sized screen, with the default fake
/// dashboard and sales, whose recent sales share IDs.
Future<void> pumpApp(WidgetTester tester) async {
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
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('See all opens Sales history, and back returns home', (
    tester,
  ) async {
    await pumpApp(tester);

    await scrollToAndTap(tester, find.text('See all'));
    expect(find.byType(SalesHistoryPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('a recent sale opens its details, and back returns home', (
    tester,
  ) async {
    await pumpApp(tester);

    await scrollToAndTap(tester, find.text('Sale #0141'));
    expect(find.byType(SaleDetailsPage), findsOneWidget);
    expect(find.text('ORS sachets'), findsOneWidget);

    // Back skips Sales history because the sale was opened from Home.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.byType(SalesHistoryPage), findsNothing);
  });
}
