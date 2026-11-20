import '../../../core/utils/expiry_status.dart';
import 'entities/alert_product.dart';
import 'entities/stock_alert.dart';

/// Works out every alert for [products] on [today].
///
/// - **Expired**: a batch past its expiry date that still has stock.
/// - **Expiring soon**: a batch expiring within [expiryAlertDays]. A batch
///   expiring today is still sellable, so it counts here, not as expired.
/// - **Low stock**: a product whose sellable units (unexpired batches only)
///   are at or below its reorder level, or [lowStockThreshold] when it has
///   none. Expired units don't count because they can't be sold.
///
/// Empty batches are ignored. The result is ordered expired first (oldest
/// expiry first), then expiring soon (soonest first), then low stock (fewest
/// units first).
List<StockAlert> buildStockAlerts(
  List<AlertProduct> products, {
  required DateTime today,
  required int lowStockThreshold,
  required int expiryAlertDays,
}) {
  final expired = <StockAlert>[];
  final expiring = <StockAlert>[];
  final lowStock = <StockAlert>[];

  for (final product in products) {
    var sellableUnits = 0;

    for (final batch in product.batches) {
      if (batch.quantity <= 0) continue;

      final status = expiryStatusFor(
        batch.expiryDate,
        today: today,
        alertDays: expiryAlertDays,
      );
      if (status != ExpiryStatus.expired) sellableUnits += batch.quantity;

      final type = switch (status) {
        ExpiryStatus.expired => StockAlertType.expired,
        ExpiryStatus.expiringSoon => StockAlertType.expiringSoon,
        ExpiryStatus.inDate => null,
      };
      if (type == null) continue;

      (type == StockAlertType.expired ? expired : expiring).add(
        StockAlert(
          type: type,
          productId: product.id,
          productName: product.name,
          quantity: batch.quantity,
          batchId: batch.id,
          batchNumber: batch.batchNumber,
          expiryDate: batch.expiryDate,
        ),
      );
    }

    final reorderLevel = product.reorderLevel ?? lowStockThreshold;
    if (sellableUnits <= reorderLevel) {
      lowStock.add(
        StockAlert(
          type: StockAlertType.lowStock,
          productId: product.id,
          productName: product.name,
          quantity: sellableUnits,
          reorderLevel: reorderLevel,
        ),
      );
    }
  }

  // Ties are broken by name so the order never changes between rebuilds
  // (List.sort isn't stable).
  int byName(StockAlert a, StockAlert b) =>
      a.productName.compareTo(b.productName);
  int byExpiry(StockAlert a, StockAlert b) {
    final byDate = a.expiryDate!.compareTo(b.expiryDate!);
    return byDate != 0 ? byDate : byName(a, b);
  }

  expired.sort(byExpiry);
  expiring.sort(byExpiry);
  lowStock.sort((a, b) {
    final byUnits = a.quantity.compareTo(b.quantity);
    return byUnits != 0 ? byUnits : byName(a, b);
  });

  return [...expired, ...expiring, ...lowStock];
}
