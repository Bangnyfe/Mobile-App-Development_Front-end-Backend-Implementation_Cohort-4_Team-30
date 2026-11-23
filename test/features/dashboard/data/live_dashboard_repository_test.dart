import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/core/utils/formatters.dart';
import 'package:team30_app/features/dashboard/data/live_dashboard_repository.dart';
import 'package:team30_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:team30_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:team30_app/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:team30_app/features/sales/domain/entities/sale.dart';
import 'package:team30_app/features/sales/domain/repositories/sales_repository.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:team30_app/features/settings/domain/entities/app_settings.dart';

import '../../inventory/inventory_test_helpers.dart';

class _MockSales extends Mock implements SalesRepository {}

class _MockInventory extends Mock implements InventoryRepository {}

Sale _sale(String id, {required int total, int minute = 0}) => Sale(
  id: id,
  receiptNo: id,
  createdAt: DateTime(2026, 11, 22, 9, minute),
  soldBy: 'u1',
  paymentMethod: Sale.cash,
  total: total,
  cashReceived: total,
  change: 0,
  lines: [
    SaleLine(
      productId: 'p1',
      batchId: 'b1',
      productName: 'Amoxicillin 500mg',
      quantity: 1,
      unitPrice: total,
    ),
  ],
);

void main() {
  late StreamController<List<Sale>> sales;
  late StreamController<List<InventoryItem>> inventory;
  late LiveDashboardRepository repository;
  String? userName = 'Aline Uwase';

  setUp(() {
    sales = StreamController<List<Sale>>.broadcast();
    inventory = StreamController<List<InventoryItem>>.broadcast();
    final salesRepository = _MockSales();
    final inventoryRepository = _MockInventory();
    when(() => salesRepository.watchSales(limit: any(named: 'limit')))
        .thenAnswer((_) => sales.stream);
    when(inventoryRepository.watchInventory)
        .thenAnswer((_) => inventory.stream);
    userName = 'Aline Uwase';
    repository = LiveDashboardRepository(
      sales: salesRepository,
      inventory: inventoryRepository,
      userName: () => userName,
      clock: () => inventoryToday,
    );
  });

  tearDown(() async {
    await sales.close();
    await inventory.close();
  });

  test('works Home out from the sales and stock, with the settings', () async {
    final summaries = <DashboardSummary>[];
    final subscription = repository
        .watchSummary(
          const AppSettings(expiryAlertDays: 30, lowStockThreshold: 60),
        )
        .listen(summaries.add);

    sales.add([_sale('s1', total: 2500)]);
    await pumpEventQueue();
    expect(summaries, isEmpty, reason: 'waits for the stock too');

    inventory.add([
      testItem(
        batches: [
          testBatch(id: 'b1', quantity: 50),
          testBatch(id: 'b2', quantity: 4, expiresInDays: 10),
        ],
      ),
    ]);
    await pumpEventQueue();

    final summary = summaries.single;
    expect(summary.userFirstName, 'Aline');
    expect(summary.todaySalesTotal, 2500);
    expect(summary.productCount, 1);
    expect(summary.unitsInStock, 54);
    expect(summary.lowStockCount, 1);
    expect(summary.expiringWindowDays, 30);
    expect(summary.expiringBatchCount, 1);
    await subscription.cancel();
  });

  test('emits again when a sale is saved or the stock changes', () async {
    final summaries = <DashboardSummary>[];
    final subscription = repository
        .watchSummary(const AppSettings())
        .listen(summaries.add);
    sales.add(const []);
    inventory.add([testItem()]);
    await pumpEventQueue();

    sales.add([_sale('s1', total: 4000)]);
    await pumpEventQueue();
    inventory.add([
      testItem(batches: [testBatch(quantity: 10)]),
    ]);
    await pumpEventQueue();

    expect(summaries.map((s) => s.todaySalesTotal), [0, 4000, 4000]);
    expect(summaries.map((s) => s.unitsInStock), [50, 50, 10]);
    await subscription.cancel();
  });

  test('greets whoever is signed in when it emits', () async {
    final summaries = <DashboardSummary>[];
    final subscription = repository
        .watchSummary(const AppSettings())
        .listen(summaries.add);
    sales.add(const []);
    inventory.add(const []);
    await pumpEventQueue();

    userName = null;
    sales.add(const []);
    await pumpEventQueue();

    expect(summaries.map((s) => s.userFirstName), ['Aline', '']);
    await subscription.cancel();
  });

  test('passes on errors, e.g. no pharmacy or no connection', () async {
    final errors = <Object>[];
    final subscription = repository
        .watchSummary(const AppSettings())
        .listen((_) {}, onError: errors.add);

    inventory.addError(StateError('offline'));
    await pumpEventQueue();

    expect(errors, [isA<StateError>()]);
    await subscription.cancel();
  });

  testWidgets('Home shows a new sale as soon as it is saved', (tester) async {
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
        dashboardRepository: repository,
      ),
    );
    sales.add([_sale('0001', total: 2500, minute: 5)]);
    inventory.add([testItem()]);
    await tester.pumpAndSettle();

    expect(find.text(Formatters.rwf(2500)), findsOneWidget);
    expect(find.textContaining('Aline'), findsOneWidget);

    sales.add([
      _sale('0002', total: 6900, minute: 40),
      _sale('0001', total: 2500, minute: 5),
    ]);
    await tester.pumpAndSettle();

    expect(find.text(Formatters.rwf(9400)), findsOneWidget);
    expect(find.textContaining('0002'), findsOneWidget);
  });
}
