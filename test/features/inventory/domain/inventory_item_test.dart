import 'package:flutter_test/flutter_test.dart';

import '../inventory_test_helpers.dart';

void main() {
  final today = inventoryToday;

  final item = testItem(
    batches: [
      testBatch(id: 'old', expiresInDays: -5, quantity: 10),
      testBatch(id: 'empty', expiresInDays: 30, quantity: 0),
      testBatch(id: 'next', expiresInDays: 60, quantity: 15),
      testBatch(id: 'late', expiresInDays: 400, quantity: 20),
    ],
  );

  test('totalUnits counts every unit on the shelf', () {
    expect(item.totalUnits, 45);
  });

  test('sellable units leave expired batches out', () {
    expect(item.sellableUnitsOn(today), 35);
    expect(item.expiredUnitsOn(today), 10);
  });

  test('stockValue is every batch at cost', () {
    expect(item.stockValue, 45 * 3000);
  });

  test('batchesInStock leaves empty batches out', () {
    expect(item.batchesInStock.map((b) => b.id), ['old', 'next', 'late']);
  });

  test('the next to expire is the earliest in-date batch with stock', () {
    expect(item.nextToExpireOn(today)?.id, 'next');
  });

  test('has expired stock while an expired batch has units', () {
    expect(item.hasExpiredStockOn(today), isTrue);
    final cleared = testItem(
      batches: [testBatch(expiresInDays: -5, quantity: 0)],
    );
    expect(cleared.hasExpiredStockOn(today), isFalse);
  });

  group('isExpiringSoonOn', () {
    test('is true when the next batch expires within the alert period', () {
      expect(item.isExpiringSoonOn(today, alertDays: 90), isTrue);
    });

    test('is false when it expires after the alert period', () {
      expect(item.isExpiringSoonOn(today, alertDays: 30), isFalse);
    });

    test('is false with no stock at all', () {
      expect(
        testItem(batches: []).isExpiringSoonOn(today, alertDays: 90),
        isFalse,
      );
    });
  });

  group('isLowStockOn', () {
    test('compares sellable units with the default level', () {
      expect(item.isLowStockOn(today, defaultReorderLevel: 35), isTrue);
      expect(item.isLowStockOn(today, defaultReorderLevel: 34), isFalse);
    });

    test('uses the product level over the default', () {
      final ownLevel = testItem(
        reorderLevel: 100,
        batches: [testBatch(quantity: 50)],
      );
      expect(ownLevel.isLowStockOn(today, defaultReorderLevel: 20), isTrue);
    });

    test('expired units do not hide low stock', () {
      final mostlyExpired = testItem(
        batches: [
          testBatch(id: 'a', expiresInDays: -1, quantity: 500),
          testBatch(id: 'b', expiresInDays: 100, quantity: 5),
        ],
      );
      expect(
        mostlyExpired.isLowStockOn(today, defaultReorderLevel: 20),
        isTrue,
      );
    });
  });
}
