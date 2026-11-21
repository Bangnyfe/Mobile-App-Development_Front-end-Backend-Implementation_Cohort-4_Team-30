import 'dart:async';

import 'package:team30_app/features/notifications/domain/entities/alert_product.dart';
import 'package:team30_app/features/notifications/domain/entities/stock_alert.dart';
import 'package:team30_app/features/notifications/domain/repositories/seen_alerts_repository.dart';
import 'package:team30_app/features/notifications/domain/repositories/stock_alerts_repository.dart';

/// Fixed "today" for every notifications test.
final testToday = DateTime(2026, 11, 20, 10);

DateTime daysFromToday(int days) =>
    DateTime(testToday.year, testToday.month, testToday.day + days);

/// Stock that the test pushes in by hand with [controller].
class StubStockAlertsRepository implements StockAlertsRepository {
  final controller = StreamController<List<AlertProduct>>.broadcast();

  @override
  Stream<List<AlertProduct>> watchStock() => controller.stream;
}

/// Stock that is always [products], or always fails when [fail] is set.
class FixedStockAlertsRepository implements StockAlertsRepository {
  FixedStockAlertsRepository(this.products, {this.fail = false});

  final List<AlertProduct> products;
  bool fail;

  @override
  Stream<List<AlertProduct>> watchStock() =>
      fail ? Stream.error(Exception('offline')) : Stream.value(products);
}

class FailingSeenAlertsRepository implements SeenAlertsRepository {
  @override
  Future<Set<String>> loadSeenIds() => Future.error(Exception('disk'));

  @override
  Future<void> saveSeenIds(Set<String> ids) => Future.error(Exception('disk'));
}

/// One product with a batch expiring in [expiresIn] days, plus a spare
/// in-date batch so it's never also low on stock.
AlertProduct productExpiringIn(
  int expiresIn, {
  String id = 'p1',
  String name = 'Paracetamol 500mg',
  int quantity = 100,
}) => AlertProduct(
  id: id,
  name: name,
  reorderLevel: 1,
  batches: [
    AlertBatch(
      id: 'b-$id',
      batchNumber: 'B-${id.toUpperCase()}',
      expiryDate: daysFromToday(expiresIn),
      quantity: quantity,
    ),
    AlertBatch(
      id: 'spare-$id',
      batchNumber: 'S-${id.toUpperCase()}',
      expiryDate: daysFromToday(1000),
      quantity: 10,
    ),
  ],
);

/// A low-stock alert as the page shows it.
StockAlert lowStockAlert({
  String id = 'p1',
  String name = 'Ibuprofen 200mg',
  int quantity = 12,
  int reorderLevel = 25,
}) => StockAlert(
  type: StockAlertType.lowStock,
  productId: id,
  productName: name,
  quantity: quantity,
  reorderLevel: reorderLevel,
);

/// An expiry alert as the page shows it.
StockAlert expiryAlert({
  required StockAlertType type,
  required int expiresIn,
  String batchId = 'b1',
  String name = 'Amoxicillin 500mg',
  int quantity = 40,
}) => StockAlert(
  type: type,
  productId: 'p-$batchId',
  productName: name,
  quantity: quantity,
  batchId: batchId,
  batchNumber: batchId.toUpperCase(),
  expiryDate: daysFromToday(expiresIn),
);
