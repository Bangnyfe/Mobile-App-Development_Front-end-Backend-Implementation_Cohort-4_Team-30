import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/core/router/route_paths.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/features/sales/data/fake_sales_repository.dart';
import 'package:team30_app/features/sales/domain/repositories/sales_repository.dart';
import 'package:team30_app/features/sales/presentation/cubit/sales_history_cubit.dart';
import 'package:team30_app/features/sales/presentation/pages/sales_history_page.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';

import '../sales_test_helpers.dart';

/// Thursday afternoon, so the fake sales fall on Today, Yesterday and
/// Tuesday.
final _now = DateTime(2026, 11, 19, 15);

Future<void> pumpHistory(
  WidgetTester tester, {
  SalesRepository? repository,
  Size physicalSize = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: BlocProvider(
        create: (_) => SalesHistoryCubit(
          repository ?? FakeSalesRepository(clock: () => _now),
        )..start(),
        child: SalesHistoryPage(clock: () => _now),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('groups sales under Today, Yesterday and older dates', (
    tester,
  ) async {
    await pumpHistory(tester);

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('3 sales · RWF 27,800'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
    expect(find.text('2 sales · RWF 15,600'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('TUESDAY, 17 NOV'), 200);
    expect(find.text('1 sale · RWF 9,000'), findsOneWidget);
  });

  testWidgets('shows each sale\'s receipt, time, items, payment and seller', (
    tester,
  ) async {
    await pumpHistory(tester);

    expect(find.text('Sale #0142'), findsOneWidget);
    expect(find.text('14:32 · 3 items · Cash · Aline Uwase'), findsOneWidget);
    expect(find.text('6,900'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no sales', (tester) async {
    await pumpHistory(tester, repository: StubSalesRepository());

    expect(find.text('No sales yet'), findsOneWidget);
  });

  testWidgets('offers a retry when sales fail to load', (tester) async {
    final repository = StubSalesRepository(
      sales: [buildSale(receiptNo: '0007', createdAt: _now)],
      fail: true,
    );
    await pumpHistory(tester, repository: repository);

    expect(find.text(SalesHistoryCubit.loadFailedMessage), findsOneWidget);

    repository.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Sale #0007'), findsOneWidget);
  });

  testWidgets('says when only the latest sales are shown', (tester) async {
    await pumpHistory(
      tester,
      repository: StubSalesRepository(
        sales: [
          for (var i = 0; i < SalesRepository.defaultLimit; i++)
            buildSale(id: '$i', createdAt: _now),
        ],
      ),
    );

    final footer = find.text(
      'Showing the latest ${SalesRepository.defaultLimit} sales.',
    );
    await tester.scrollUntilVisible(footer, 500);
    expect(footer, findsOneWidget);
  });

  testWidgets('tapping a sale opens the details path it was given', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(
          path: '/history',
          builder: (context, state) => BlocProvider(
            create: (_) =>
                SalesHistoryCubit(FakeSalesRepository(clock: () => _now))
                  ..start(),
            child: SalesHistoryPage(
              clock: () => _now,
              saleDetailsPath: (saleId) => '/elsewhere/$saleId',
            ),
          ),
        ),
        GoRoute(
          path: '/elsewhere/:saleId',
          builder: (context, state) =>
              Text('Opened ${state.pathParameters['saleId']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sale #0141'));
    await tester.pumpAndSettle();

    expect(find.text('Opened sale-0141'), findsOneWidget);
  });

  testWidgets('fits in landscape without overflowing', (tester) async {
    await pumpHistory(tester, physicalSize: const Size(2400, 1080));

    expect(tester.takeException(), isNull);
    expect(find.text('TODAY'), findsOneWidget);
  });

  testWidgets('opens inside the Home tab with the bottom bar visible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final router = createAppRouter();
    await tester.pumpWidget(
      PharmacyApp(
        router: router,
        settingsRepository: SharedPrefsSettingsRepository(
          await SharedPreferences.getInstance(),
        ),
        salesRepository: FakeSalesRepository(clock: () => _now),
      ),
    );
    await tester.pumpAndSettle();

    router.go(RoutePaths.salesHistory);
    await tester.pumpAndSettle();

    expect(find.byType(SalesHistoryPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
}
