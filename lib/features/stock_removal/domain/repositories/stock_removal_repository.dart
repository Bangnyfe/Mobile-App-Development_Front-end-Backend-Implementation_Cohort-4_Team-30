import '../entities/removable_product.dart';
import '../entities/stock_removal.dart';

/// Thrown by [StockRemovalRepository] with a message ready to show.
class StockRemovalFailure implements Exception {
  const StockRemovalFailure(this.message);

  final String message;

  @override
  String toString() => 'StockRemovalFailure: $message';
}

/// Everything the Remove stock screens need from the backend.
abstract interface class StockRemovalRepository {
  /// Products with at least one unit in stock, batches sorted by expiry.
  Future<List<RemovableProduct>> loadProducts();

  /// Records the removal and lowers the batch's quantity as one operation:
  /// either both happen or neither does.
  ///
  /// Throws [StockRemovalFailure] if the batch no longer has enough units
  /// (for example, someone sold from it meanwhile) or the save fails.
  Future<StockRemoval> removeStock(StockRemovalRequest request);
}
