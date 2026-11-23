import '../../inventory/domain/entities/inventory_item.dart';
import '../../inventory/domain/repositories/inventory_repository.dart';
import '../domain/entities/alert_product.dart';
import '../domain/repositories/stock_alerts_repository.dart';

/// The alerts' products and batches, read through the inventory, so the
/// bell, Home and the Stock tab always agree about what is low, expiring
/// or expired.
///
/// Emits again whenever stock is added, sold or removed.
class InventoryStockAlertsRepository implements StockAlertsRepository {
  const InventoryStockAlertsRepository(this._inventory);

  final InventoryRepository _inventory;

  @override
  Stream<List<AlertProduct>> watchStock() => _inventory.watchInventory().map(
    (items) => [for (final item in items) alertProductFrom(item)],
  );
}

/// [item] as the alerts need it: its name, own reorder level (null to use
/// the Settings threshold) and batches.
AlertProduct alertProductFrom(InventoryItem item) => AlertProduct(
  id: item.product.id,
  name: item.product.name,
  reorderLevel: item.product.reorderLevel,
  batches: [
    for (final batch in item.batches)
      AlertBatch(
        id: batch.id,
        batchNumber: batch.batchNumber,
        expiryDate: batch.expiryDate,
        quantity: batch.quantity,
      ),
  ],
);
