import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/inventory/domain/inventory_filter.dart';

import '../inventory_test_helpers.dart';

void main() {
  final rules = InventoryRules(
    today: inventoryToday,
    alertDays: 90,
    defaultReorderLevel: 20,
  );

  final healthy = testItem(
    id: 'healthy',
    name: 'Paracetamol 500mg',
    barcode: '6001007045678',
    batches: [
      testBatch(productId: 'healthy', expiresInDays: 300, quantity: 120),
    ],
  );
  final low = testItem(
    id: 'low',
    name: 'Ibuprofen 400mg',
    barcode: '6001007034566',
    batches: [testBatch(productId: 'low', expiresInDays: 300, quantity: 8)],
  );
  final expiring = testItem(
    id: 'expiring',
    name: 'Omeprazole 20mg',
    barcode: '6001007067892',
    batches: [
      testBatch(productId: 'expiring', expiresInDays: 45, quantity: 60),
    ],
  );
  final expired = testItem(
    id: 'expired',
    name: 'Metronidazole 400mg',
    barcode: '6001007012342',
    batches: [
      testBatch(id: 'x', productId: 'expired', expiresInDays: -3, quantity: 4),
      testBatch(
        id: 'y',
        productId: 'expired',
        expiresInDays: 500,
        quantity: 90,
      ),
    ],
  );
  final items = [healthy, low, expiring, expired];

  group('matches', () {
    test('All shows everything', () {
      expect(rules.apply(items), items);
    });

    test('Low stock', () {
      expect(rules.apply(items, filter: InventoryFilter.lowStock), [low]);
    });

    test('Expiring soon follows the alert period', () {
      expect(rules.apply(items, filter: InventoryFilter.expiringSoon), [
        expiring,
      ]);
      final shortAlerts = InventoryRules(
        today: inventoryToday,
        alertDays: 30,
        defaultReorderLevel: 20,
      );
      expect(
        shortAlerts.apply(items, filter: InventoryFilter.expiringSoon),
        isEmpty,
      );
    });

    test('Expired shows products with expired units on the shelf', () {
      expect(rules.apply(items, filter: InventoryFilter.expired), [expired]);
    });
  });

  group('search', () {
    test('matches part of the name, ignoring case', () {
      expect(rules.apply(items, query: '  ibu '), [low]);
    });

    test('matches part of the barcode', () {
      expect(rules.apply(items, query: '45678'), [healthy]);
    });

    test('combines with the filter', () {
      expect(
        rules.apply(items, filter: InventoryFilter.lowStock, query: 'para'),
        isEmpty,
      );
    });
  });

  test('counts each filter for the chips', () {
    expect(rules.counts(items), {
      InventoryFilter.all: 4,
      InventoryFilter.lowStock: 1,
      InventoryFilter.expiringSoon: 1,
      InventoryFilter.expired: 1,
    });
  });

  test('fromName reads a link, falling back to All', () {
    expect(InventoryFilter.fromName('lowStock'), InventoryFilter.lowStock);
    expect(InventoryFilter.fromName('nonsense'), InventoryFilter.all);
    expect(InventoryFilter.fromName(null), InventoryFilter.all);
  });
}
