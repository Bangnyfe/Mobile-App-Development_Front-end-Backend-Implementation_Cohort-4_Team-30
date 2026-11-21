import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:team30_app/features/notifications/data/fake_stock_alerts_repository.dart';
import 'package:team30_app/features/notifications/data/in_memory_seen_alerts_repository.dart';
import 'package:team30_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';

/// The whole app on a phone-sized screen with the sample stock, which
/// gives 8 alerts with the default settings.
Future<void> pumpApp(
  WidgetTester tester, {
  InMemorySeenAlertsRepository? seen,
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  await tester.pumpWidget(
    PharmacyApp(
      router: createAppRouter(),
      settingsRepository: SharedPrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      ),
      stockAlertsRepository: FakeStockAlertsRepository(),
      seenAlertsRepository: seen,
    ),
  );
  await tester.pumpAndSettle();
}

Badge bellBadge(WidgetTester tester) => tester.widget<Badge>(
  find.descendant(
    of: find.byTooltip(RegExp('^Notifications')),
    matching: find.byType(Badge),
  ),
);

int selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  testWidgets('the bell shows how many alerts are new', (tester) async {
    await pumpApp(tester);

    expect(bellBadge(tester).isLabelVisible, isTrue);
    expect(find.byTooltip('Notifications, 8 new'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byTooltip('Notifications, 8 new'),
        matching: find.text('8'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the bell opens Notifications in the Home tab, and the badge '
      'clears after leaving', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Notifications, 8 new'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(selectedTab(tester), 0);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(bellBadge(tester).isLabelVisible, isFalse);
  });

  testWidgets('alerts seen before do not count', (tester) async {
    await pumpApp(
      tester,
      seen: InMemorySeenAlertsRepository({
        'expired:b-amx-2309',
        'low:metformin-500',
      }),
    );

    expect(find.byTooltip('Notifications, 6 new'), findsOneWidget);
  });

  testWidgets('follows the alert period from Settings', (tester) async {
    // With 30 days, ORS sachets (45 days left) aren't expiring soon.
    await pumpApp(
      tester,
      prefs: {SharedPrefsSettingsRepository.expiryAlertDaysKey: 30},
    );

    expect(find.byTooltip('Notifications, 7 new'), findsOneWidget);
  });
}
