import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:team30_app/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:team30_app/features/notifications/data/inventory_stock_alerts_repository.dart';
import 'package:team30_app/features/notifications/domain/build_stock_alerts.dart';
import 'package:team30_app/features/notifications/domain/entities/alert_product.dart';
import 'package:team30_app/features/notifications/domain/entities/stock_alert.dart';

import '../../inventory/inventory_test_helpers.dart';

class _MockInventory extends Mock implements InventoryRepository {}

void main() {
  group('alertProductFrom', () {
    test('copies the name, reorder level and every batch', () {
      final product = alertProductFrom(
        testItem(
          id: 'p1',
          name: 'Amoxicillin 500mg',
          reorderLevel: 30,
          batches: [
            testBatch(id: 'b1', batchNumber: 'AMX-1', quantity: 12),
            testBatch(
              id: 'b2',
              batchNumber: 'AMX-2',
              quantity: 0,
              expiresInDays: -4,
            ),
          ],
        ),
      );

      expect(
        product,
        AlertProduct(
          id: 'p1',
          name: 'Amoxicillin 500mg',
          reorderLevel: 30,
          batches: [
            AlertBatch(
              id: 'b1',
              batchNumber: 'AMX-1',
              expiryDate: DateTime(2027, 6, 10),
              quantity: 12,
            ),
            AlertBatch(
              id: 'b2',
              batchNumber: 'AMX-2',
              expiryDate: DateTime(2026, 11, 18),
              quantity: 0,
            ),
          ],
        ),
      );
    });

    test('no reorder level means the Settings threshold applies', () {
      expect(alertProductFrom(testItem()).reorderLevel, isNull);
    });
  });

  group('watchStock', () {
    late StreamController<List<InventoryItem>> inventory;
    late InventoryStockAlertsRepository repository;

    setUp(() {
      inventory = StreamController<List<InventoryItem>>();
      final inventoryRepository = _MockInventory();
      when(inventoryRepository.watchInventory)
          .thenAnswer((_) => inventory.stream);
      repository = InventoryStockAlertsRepository(inventoryRepository);
    });

    tearDown(() => inventory.close());

    test('emits again whenever the stock changes', () async {
      final emitted = <List<AlertProduct>>[];
      final subscription = repository.watchStock().listen(emitted.add);

      inventory.add([testItem(id: 'p1')]);
      inventory.add([
        testItem(id: 'p1'),
        testItem(id: 'p2', name: 'Paracetamol 500mg'),
      ]);
      await pumpEventQueue();

      expect(emitted.map((products) => products.length), [1, 2]);
      expect(emitted.last.last.name, 'Paracetamol 500mg');
      await subscription.cancel();
    });

    test('passes on errors, e.g. no pharmacy or no connection', () async {
      final errors = <Object>[];
      final subscription = repository.watchStock().listen(
        (_) {},
        onError: errors.add,
      );

      inventory.addError(StateError('offline'));
      await pumpEventQueue();

      expect(errors, [isA<StateError>()]);
      await subscription.cancel();
    });

    test('gives the alerts the Stock tab would show', () async {
      final products = repository.watchStock().first;
      inventory.add([
        // Expired batch still on the shelf, and 10 sellable units: low.
        testItem(
          id: 'p1',
          name: 'Amoxicillin 500mg',
          batches: [
            testBatch(id: 'b1', quantity: 5, expiresInDays: -2),
            testBatch(id: 'b2', quantity: 10, expiresInDays: 200),
          ],
        ),
        // Expiring within 30 days, plenty of stock.
        testItem(
          id: 'p2',
          name: 'Paracetamol 500mg',
          batches: [testBatch(id: 'b3', quantity: 80, expiresInDays: 12)],
        ),
      ]);

      final alerts = buildStockAlerts(
        await products,
        today: inventoryToday,
        lowStockThreshold: 20,
        expiryAlertDays: 30,
      );

      expect(alerts.map((alert) => (alert.type, alert.productName)), [
        (StockAlertType.expired, 'Amoxicillin 500mg'),
        (StockAlertType.expiringSoon, 'Paracetamol 500mg'),
        (StockAlertType.lowStock, 'Amoxicillin 500mg'),
      ]);
    });
  });
}
