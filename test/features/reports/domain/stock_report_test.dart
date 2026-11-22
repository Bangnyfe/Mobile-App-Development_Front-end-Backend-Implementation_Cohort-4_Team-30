import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/reports/domain/report_period.dart';
import 'package:team30_app/features/reports/domain/stock_report.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removable_product.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removal_reason.dart';
import 'package:team30_app/features/stock_removal/domain/entities/stock_removal.dart';

StockRemoval _removal(
  DateTime at,
  int units,
  int value, {
  RemovalReason reason = RemovalReason.expired,
}) => StockRemoval(
  id: '$at',
  productId: 'p',
  productName: 'Product',
  batchId: 'b',
  batchNumber: 'B1',
  quantity: units,
  reason: reason,
  costValue: value,
  removedBy: 'u1',
  removedByName: 'Aline',
  createdAt: at,
);

void main() {
  final today = DateTime(2026, 11, 22, 9, 30);

  test('periods start on the 1st of their first month', () {
    expect(ReportPeriod.thisMonth.startOn(today), DateTime(2026, 11));
    expect(ReportPeriod.threeMonths.startOn(today), DateTime(2026, 9));
    expect(ReportPeriod.year.startOn(today), DateTime(2025, 12));
    expect(
      ReportPeriod.threeMonths.startOn(DateTime(2026, 2, 3)),
      DateTime(2025, 12),
    );
  });

  test('totals count removals, units and value', () {
    final totals = totalsOf([
      _removal(today, 8, 6400),
      _removal(today, 4, 14000),
    ]);
    expect(totals, const RemovalTotals(count: 2, units: 12, value: 20400));
    expect(totalsOf(const []), RemovalTotals.zero);
  });

  test('removalsSince keeps removals from the start date onwards', () {
    final removals = [
      _removal(DateTime(2026, 11, 1), 1, 100),
      _removal(DateTime(2026, 10, 31, 23, 59), 1, 100),
    ];
    expect(removalsSince(removals, DateTime(2026, 11)), [removals.first]);
  });

  final products = [
    RemovableProduct(
      id: 'p1',
      name: 'Metronidazole 400mg',
      barcode: '1',
      batches: [
        RemovableBatch(
          id: 'b1',
          batchNumber: 'MZ2308',
          expiryDate: DateTime(2026, 10, 28),
          quantity: 14,
          costPrice: 1100,
        ),
        RemovableBatch(
          id: 'b2',
          batchNumber: 'MZ2410',
          expiryDate: DateTime(2028),
          quantity: 9,
          costPrice: 1100,
        ),
      ],
    ),
    RemovableProduct(
      id: 'p2',
      name: 'Cough syrup 100ml',
      barcode: '2',
      batches: [
        RemovableBatch(
          id: 'b3',
          batchNumber: 'CS-118',
          expiryDate: DateTime(2026, 11, 19),
          quantity: 6,
          costPrice: 1800,
        ),
      ],
    ),
  ];

  test('stock value is every unit at its cost price', () {
    expect(stockValueAtCost(products), 23 * 1100 + 6 * 1800);
  });

  test('expired stock on the shelf, longest expired first', () {
    final lines = expiredOnShelf(products, today);

    expect(lines.map((l) => l.batchNumber), ['MZ2308', 'CS-118']);
    expect(lines.first.value, 15400);
    expect(lines.first.productId, 'p1');
  });

  test('expired value by month fills empty months and ignores other '
      'reasons', () {
    final totals = expiredValueByMonth(
      [
        _removal(DateTime(2026, 11, 20), 8, 6400),
        _removal(
          DateTime(2026, 11, 16),
          4,
          14000,
          reason: RemovalReason.damaged,
        ),
        _removal(DateTime(2026, 9, 13), 10, 11000),
        _removal(DateTime(2026, 7, 15), 30, 13500),
      ],
      today: today,
      months: 3,
    );

    expect(totals, [
      MonthTotal(month: DateTime(2026, 9), value: 11000),
      MonthTotal(month: DateTime(2026, 10), value: 0),
      MonthTotal(month: DateTime(2026, 11), value: 6400),
    ]);
  });
}
