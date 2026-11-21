import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:team30_app/core/router/route_paths.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/features/reports/presentation/pages/reports_hub_page.dart';

/// The hub with stand-in report pages, so taps can be checked without the
/// real reports.
Future<void> pumpHub(
  WidgetTester tester, {
  Size physicalSize = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  Widget opened(String name) => Scaffold(body: Text('Opened $name'));

  final router = GoRouter(
    initialLocation: RoutePaths.reports,
    routes: [
      GoRoute(
        path: RoutePaths.reports,
        builder: (context, state) => const ReportsHubPage(),
        routes: [
          GoRoute(path: 'sales', builder: (_, _) => opened('sales')),
          GoRoute(path: 'inventory', builder: (_, _) => opened('inventory')),
          GoRoute(path: 'expiry-waste', builder: (_, _) => opened('expiry')),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every report under Sales and Stock', (tester) async {
    await pumpHub(tester);

    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('SALES'), findsOneWidget);
    expect(find.text('Sales history'), findsOneWidget);
    expect(find.text('STOCK'), findsOneWidget);
    expect(find.text('Inventory report'), findsOneWidget);
    expect(find.text('Expiry & waste report'), findsOneWidget);
  });

  for (final (title, opened) in [
    ('Sales history', 'Opened sales'),
    ('Inventory report', 'Opened inventory'),
    ('Expiry & waste report', 'Opened expiry'),
  ]) {
    testWidgets('tapping $title opens it', (tester) async {
      await pumpHub(tester);

      await tester.tap(find.text(title));
      await tester.pumpAndSettle();

      expect(find.text(opened), findsOneWidget);
    });
  }

  testWidgets('fits in landscape without overflowing', (tester) async {
    await pumpHub(tester, physicalSize: const Size(2400, 1080));

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Expiry & waste report'), 100);
    expect(find.text('Expiry & waste report'), findsOneWidget);
  });
}
