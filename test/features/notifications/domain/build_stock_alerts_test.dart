import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/notifications/domain/build_stock_alerts.dart';
import 'package:team30_app/features/notifications/domain/entities/alert_product.dart';
import 'package:team30_app/features/notifications/domain/entities/stock_alert.dart';

final today = DateTime(2026, 11, 20, 15, 30);

DateTime inDays(int days) =>
    DateTime(today.year, today.month, today.day + days);

AlertBatch batch(String id, {required int expiresIn, int quantity = 100}) =>
    AlertBatch(
      id: id,
      batchNumber: id.toUpperCase(),
      expiryDate: inDays(expiresIn),
      quantity: quantity,
    );

List<StockAlert> alertsFor(
  List<AlertProduct> products, {
  int lowStockThreshold = 20,
  int expiryAlertDays = 90,
}) => buildStockAlerts(
  products,
  today: today,
  lowStockThreshold: lowStockThreshold,
  expiryAlertDays: expiryAlertDays,
);

void main() {
  group('expiry alerts', () {
    test('a batch past its expiry date is expired', () {
      final alerts = alertsFor([
        AlertProduct(
          id: 'p',
          name: 'P',
          // An in-date batch too, so the product isn't also low on stock.
          batches: [batch('b1', expiresIn: -1), batch('b2', expiresIn: 200)],
        ),
      ]);

      expect(alerts.single.type, StockAlertType.expired);
      expect(alerts.single.batchNumber, 'B1');
      expect(alerts.single.quantity, 100);
      expect(alerts.single.id, 'expired:b1');
    });

    test('a batch expiring today is expiring soon, not expired', () {
      final alerts = alertsFor([
        AlertProduct(id: 'p', name: 'P', batches: [batch('b1', expiresIn: 0)]),
      ]);

      expect(alerts.single.type, StockAlertType.expiringSoon);
      expect(alerts.single.id, 'expiring:b1');
    });

    test('uses the expiry alert period from Settings', () {
      final product = AlertProduct(
        id: 'p',
        name: 'P',
        batches: [batch('b1', expiresIn: 30)],
      );

      expect(alertsFor([product], expiryAlertDays: 30), hasLength(1));
      expect(alertsFor([product], expiryAlertDays: 29), isEmpty);
    });

    test('ignores empty batches', () {
      final alerts = alertsFor([
        AlertProduct(
          id: 'p',
          name: 'P',
          batches: [
            batch('old', expiresIn: -5, quantity: 0),
            batch('new', expiresIn: 200),
          ],
        ),
      ]);

      expect(alerts, isEmpty);
    });
  });

  group('low-stock alerts', () {
    test('a product exactly at its reorder level is low on stock', () {
      final alerts = alertsFor([
        AlertProduct(
          id: 'p',
          name: 'P',
          reorderLevel: 25,
          batches: [batch('b1', expiresIn: 200, quantity: 25)],
        ),
      ]);

      expect(alerts.single.type, StockAlertType.lowStock);
      expect(alerts.single.quantity, 25);
      expect(alerts.single.reorderLevel, 25);
      expect(alerts.single.id, 'low:p');
      expect(alerts.single.isOutOfStock, isFalse);
    });

    test('a product above its reorder level has no alert', () {
      final alerts = alertsFor([
        AlertProduct(
          id: 'p',
          name: 'P',
          reorderLevel: 25,
          batches: [batch('b1', expiresIn: 200, quantity: 26)],
        ),
      ]);

      expect(alerts, isEmpty);
    });

    test('without its own level, uses the threshold from Settings', () {
      final product = AlertProduct(
        id: 'p',
        name: 'P',
        batches: [batch('b1', expiresIn: 200, quantity: 15)],
      );

      expect(alertsFor([product], lowStockThreshold: 15), hasLength(1));
      expect(alertsFor([product], lowStockThreshold: 14), isEmpty);
      expect(
        alertsFor([product], lowStockThreshold: 15).single.reorderLevel,
        15,
      );
    });

    test('adds up units across batches', () {
      final alerts = alertsFor([
        AlertProduct(
          id: 'p',
          name: 'P',
          reorderLevel: 20,
          batches: [
            batch('b1', expiresIn: 200, quantity: 12),
            batch('b2', expiresIn: 300, quantity: 9),
          ],
        ),
      ]);

      expect(alerts, isEmpty);
    });

    test('expired units do not count towards stock', () {
      final alerts = alertsFor([
        AlertProduct(
          id: 'p',
          name: 'P',
          reorderLevel: 20,
          batches: [
            batch('old', expiresIn: -2, quantity: 50),
            batch('new', expiresIn: 200, quantity: 10),
          ],
        ),
      ]);

      expect(alerts.map((a) => a.type), [
        StockAlertType.expired,
        StockAlertType.lowStock,
      ]);
      expect(alerts.last.quantity, 10);
    });

    test('a product with no batches is out of stock', () {
      final alerts = alertsFor([const AlertProduct(id: 'p', name: 'P')]);

      expect(alerts.single.type, StockAlertType.lowStock);
      expect(alerts.single.quantity, 0);
      expect(alerts.single.isOutOfStock, isTrue);
    });
  });

  test('orders expired, then expiring soon, then low stock', () {
    final alerts = alertsFor([
      const AlertProduct(id: 'z', name: 'Zinc', reorderLevel: 5),
      AlertProduct(
        id: 'a',
        name: 'Aspirin',
        reorderLevel: 5,
        batches: [batch('a1', expiresIn: 3, quantity: 4)],
      ),
      AlertProduct(
        id: 'b',
        name: 'Bisacodyl',
        batches: [
          batch('b1', expiresIn: -1),
          batch('b2', expiresIn: -10),
          batch('b3', expiresIn: 1),
        ],
      ),
    ]);

    expect(alerts.map((a) => a.id), [
      'expired:b2',
      'expired:b1',
      'expiring:b3',
      'expiring:a1',
      'low:z',
      'low:a',
    ]);
  });

  test('ties are ordered by product name', () {
    final alerts = alertsFor([
      const AlertProduct(id: 'm', name: 'Metformin'),
      const AlertProduct(id: 'c', name: 'Cetirizine'),
    ]);

    expect(alerts.map((a) => a.productName), ['Cetirizine', 'Metformin']);
  });

  test('no products means no alerts', () {
    expect(alertsFor(const []), isEmpty);
  });
}
