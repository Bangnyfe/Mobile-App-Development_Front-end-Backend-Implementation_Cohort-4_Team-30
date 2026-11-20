import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/core/router/route_paths.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/features/sales/data/fake_sales_repository.dart';
import 'package:team30_app/features/sales/domain/repositories/sales_repository.dart';
import 'package:team30_app/features/sales/presentation/cubit/sale_details_cubit.dart';
import 'package:team30_app/features/sales/presentation/pages/sale_details_page.dart';
import 'package:team30_app/features/sales/presentation/pages/sales_history_page.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';

import '../sales_test_helpers.dart';

final _now = DateTime(2026, 11, 19, 15);

Future<void> pumpDetails(
  WidgetTester tester,
  String saleId, {
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
        create: (_) => SaleDetailsCubit(
          repository ?? FakeSalesRepository(clock: () => _now),
          saleId,
        )..load(),
        child: const SaleDetailsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the receipt, when, who and the total', (tester) async {
    await pumpDetails(tester, 'sale-0142');

    expect(find.text('Sale #0142'), findsOneWidget);
    expect(find.text('Thursday, 19 Nov · 14:32'), findsOneWidget);
    expect(find.text('Aline Uwase'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    // In the header and on the Total row.
    expect(find.text('RWF 6,900'), findsNWidgets(2));
  });

  testWidgets('combines one product sold from two batches into one item', (
    tester,
  ) async {
    await pumpDetails(tester, 'sale-0140');

    expect(find.text('ITEMS · 5 ITEMS'), findsOneWidget);
    expect(find.text('Ibuprofen 400mg'), findsOneWidget);
    expect(find.text('2 × 1,500'), findsOneWidget);
    expect(find.text('3,000'), findsOneWidget);
    expect(find.text('Metformin 500mg'), findsOneWidget);
  });

  testWidgets('shows cash received and change for cash sales', (tester) async {
    await pumpDetails(tester, 'sale-0140');

    await tester.scrollUntilVisible(find.text('Change'), 200);
    expect(find.text('RWF 20,000'), findsOneWidget);
    expect(find.text('RWF 1,600'), findsOneWidget);
  });

  testWidgets('hides cash received and change for Mobile Money', (
    tester,
  ) async {
    await pumpDetails(tester, 'sale-0141');

    expect(find.text('Mobile Money'), findsOneWidget);
    expect(find.text('Cash received'), findsNothing);
    expect(find.text('Change'), findsNothing);
  });

  testWidgets('says when the sale does not exist', (tester) async {
    await pumpDetails(tester, 'missing');

    expect(find.text("This sale couldn't be found."), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('offers a retry when the sale fails to load', (tester) async {
    final repository = StubSalesRepository(
      sales: [buildSale(id: 's1', receiptNo: '0007', createdAt: _now)],
      fail: true,
    );
    await pumpDetails(tester, 's1', repository: repository);

    expect(find.text(SaleDetailsCubit.loadFailedMessage), findsOneWidget);

    repository.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Sale #0007'), findsOneWidget);
  });

  testWidgets('fits in landscape without overflowing', (tester) async {
    await pumpDetails(
      tester,
      'sale-0140',
      physicalSize: const Size(2400, 1080),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Sale #0140'), findsOneWidget);
  });

  testWidgets('tapping a sale in the history opens it, and back returns', (
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

    await tester.tap(find.text('Sale #0141'));
    await tester.pumpAndSettle();

    expect(find.byType(SaleDetailsPage), findsOneWidget);
    expect(find.text('ORS sachets'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(SalesHistoryPage), findsOneWidget);
    expect(find.byType(SaleDetailsPage), findsNothing);
  });
}
