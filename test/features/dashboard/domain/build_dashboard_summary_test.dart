import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/dashboard/domain/build_dashboard_summary.dart';
import 'package:team30_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:team30_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:team30_app/features/sales/domain/entities/sale.dart';

import '../../inventory/inventory_test_helpers.dart';

/// 22 Nov 2026, 09:30.
final _now = inventoryToday;

Sale _sale(
  String id, {
  required DateTime at,
  int total = 1000,
  int units = 1,
  String payment = 'Cash',
}) => Sale(
  id: id,
  receiptNo: id,
  createdAt: at,
  soldBy: 'u1',
  paymentMethod: payment,
  total: total,
  cashReceived: total,
  change: 0,
  lines: [
    SaleLine(
      productId: 'p1',
      batchId: 'b1',
      productName: 'Amoxicillin 500mg',
      quantity: units,
      unitPrice: total ~/ units,
    ),
  ],
);

DashboardSummary _summary({
  List<Sale> sales = const [],
  List<InventoryItem> inventory = const [],
  int expiryAlertDays = 30,
  int lowStockThreshold = 20,
}) => buildDashboardSummary(
  userFirstName: 'Aline',
  sales: sales,
  inventory: inventory,
  now: _now,
  expiryAlertDays: expiryAlertDays,
  lowStockThreshold: lowStockThreshold,
);

void main() {
  group('sales', () {
    test("adds up today's and yesterday's sales by calendar day", () {
      final summary = _summary(
        sales: [
          _sale('s5', at: DateTime(2026, 11, 22, 9, 15), total: 2500),
          _sale('s4', at: DateTime(2026, 11, 22, 0, 5), total: 4000),
          _sale('s3', at: DateTime(2026, 11, 21, 23, 59), total: 3000),
          _sale('s2', at: DateTime(2026, 11, 21, 8), total: 1000),
          _sale('s1', at: DateTime(2026, 11, 20, 18), total: 9000),
        ],
      );

      expect(summary.todaySalesTotal, 6500);
      expect(summary.todaySalesCount, 2);
      expect(summary.yesterdaySalesTotal, 4000);
      expect(summary.changeVsYesterday, closeTo(62.5, 0.001));
    });

    test('yesterday works across the start of a month', () {
      final summary = buildDashboardSummary(
        userFirstName: 'Aline',
        sales: [
          _sale('s2', at: DateTime(2026, 12, 1, 10), total: 500),
          _sale('s1', at: DateTime(2026, 11, 30, 10), total: 700),
        ],
        inventory: const [],
        now: DateTime(2026, 12, 1, 12),
        expiryAlertDays: 30,
        lowStockThreshold: 20,
      );

      expect(summary.todaySalesTotal, 500);
      expect(summary.yesterdaySalesTotal, 700);
    });

    test('lists the five newest sales as recent transactions', () {
      final sales = [
        for (var i = 7; i >= 1; i--)
          _sale(
            's$i',
            at: DateTime(2026, 11, 22, 8, i),
            total: i * 100,
            units: i,
            payment: i.isEven ? 'Mobile Money' : 'Cash',
          ),
      ];

      final recent = _summary(sales: sales).recentSales;

      expect(recent.map((sale) => sale.saleId), ['s7', 's6', 's5', 's4', 's3']);
      expect(recent.first.receiptNo, 's7');
      expect(recent.first.itemCount, 7);
      expect(recent.first.total, 700);
      expect(recent.first.paymentMethod, 'Cash');
      expect(recent[1].paymentMethod, 'Mobile Money');
    });

    test('no sales means zeros, no change and no recent sales', () {
      final summary = _summary();

      expect(summary.todaySalesTotal, 0);
      expect(summary.todaySalesCount, 0);
      expect(summary.changeVsYesterday, isNull);
      expect(summary.recentSales, isEmpty);
    });
  });

  group('stock', () {
    test('counts products and the units that can still be sold', () {
      final summary = _summary(
        inventory: [
          testItem(
            id: 'p1',
            batches: [
              testBatch(id: 'b1', quantity: 40),
              testBatch(id: 'b2', quantity: 15, expiresInDays: -3),
            ],
          ),
          testItem(
            id: 'p2',
            batches: [testBatch(id: 'b3', productId: 'p2')],
          ),
          testItem(id: 'p3', batches: const []),
        ],
      );

      expect(summary.productCount, 3);
      expect(summary.unitsInStock, 90);
    });

    test("low stock uses each product's reorder level, or the threshold", () {
      final summary = _summary(
        lowStockThreshold: 20,
        inventory: [
          // 20 units, threshold 20: low.
          testItem(id: 'p1', batches: [testBatch(quantity: 20)]),
          // 21 units, threshold 20: fine.
          testItem(id: 'p2', batches: [testBatch(quantity: 21)]),
          // 40 units, own reorder level 50: low.
          testItem(
            id: 'p3',
            reorderLevel: 50,
            batches: [testBatch(quantity: 40)],
          ),
          // 100 units, but all expired: nothing to sell, so low.
          testItem(
            id: 'p4',
            batches: [testBatch(quantity: 100, expiresInDays: -1)],
          ),
          // No batches at all: low.
          testItem(id: 'p5', batches: const []),
        ],
      );

      expect(summary.lowStockCount, 4);
    });
  });

  group('expiry', () {
    test('counts expiring and expired batches with units left', () {
      final summary = _summary(
        expiryAlertDays: 30,
        inventory: [
          testItem(
            id: 'p1',
            batches: [
              testBatch(id: 'b1', expiresInDays: -10, quantity: 5),
              testBatch(id: 'b2', expiresInDays: 0, quantity: 10),
              testBatch(id: 'b3', expiresInDays: 30, quantity: 4),
              testBatch(id: 'b4', expiresInDays: 31, quantity: 50),
              // Empty batches don't count, expired or not.
              testBatch(id: 'b5', expiresInDays: -2, quantity: 0),
              testBatch(id: 'b6', expiresInDays: 5, quantity: 0),
            ],
          ),
        ],
      );

      expect(summary.expiredBatchCount, 1);
      expect(summary.expiringBatchCount, 2);
      // (10 + 4) units x 3000 RWF.
      expect(summary.expiringCostValue, 42000);
      expect(summary.expiringWindowDays, 30);
    });

    test('follows the expiry alert days', () {
      final inventory = [
        testItem(batches: [testBatch(expiresInDays: 60)]),
      ];

      expect(
        _summary(inventory: inventory, expiryAlertDays: 30).expiringBatchCount,
        0,
      );
      expect(
        _summary(inventory: inventory, expiryAlertDays: 90).expiringBatchCount,
        1,
      );
    });
  });

  group('firstNameOf', () {
    test('takes the first word of the name', () {
      expect(firstNameOf('Aline Uwase'), 'Aline');
      expect(firstNameOf('  Eric   Mugisha '), 'Eric');
      expect(firstNameOf('Diane'), 'Diane');
    });

    test('is empty without a name', () {
      expect(firstNameOf(null), '');
      expect(firstNameOf('   '), '');
    });
  });
}
