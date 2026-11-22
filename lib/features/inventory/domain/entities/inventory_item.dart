import 'package:equatable/equatable.dart';

import '../../../../core/utils/expiry_status.dart';
import 'batch.dart';
import 'product.dart';

/// A product together with its batches, as the Inventory screens show it.
///
/// Expired batches still count as stock on the shelf (they must be removed),
/// but not as stock that can be sold, so they never hide a low-stock
/// warning.
class InventoryItem extends Equatable {
  /// [batches] should be sorted earliest expiry first, as the repositories
  /// return them.
  const InventoryItem({required this.product, this.batches = const []});

  final Product product;
  final List<Batch> batches;

  /// Units on the shelf, expired or not.
  int get totalUnits => batches.fold(0, (sum, batch) => sum + batch.quantity);

  /// Whole RWF the units on the shelf cost.
  int get stockValue => batches.fold(0, (sum, batch) => sum + batch.stockValue);

  /// Batches that still have units, earliest expiry first.
  List<Batch> get batchesInStock => [
    for (final batch in batches)
      if (batch.quantity > 0) batch,
  ];

  /// Units that can still be sold on [today].
  int sellableUnitsOn(DateTime today) => batches
      .where((batch) => !batch.isExpiredOn(today))
      .fold(0, (sum, batch) => sum + batch.quantity);

  /// Units past their expiry date that are still on the shelf.
  int expiredUnitsOn(DateTime today) => totalUnits - sellableUnitsOn(today);

  /// The in-date batch with stock that expires first: the one to sell next.
  Batch? nextToExpireOn(DateTime today) {
    for (final batch in batches) {
      if (batch.quantity > 0 && !batch.isExpiredOn(today)) return batch;
    }
    return null;
  }

  bool hasExpiredStockOn(DateTime today) =>
      batches.any((batch) => batch.quantity > 0 && batch.isExpiredOn(today));

  /// An in-date batch with stock expires within [alertDays].
  bool isExpiringSoonOn(DateTime today, {required int alertDays}) {
    final next = nextToExpireOn(today);
    return next != null &&
        expiryStatusFor(next.expiryDate, today: today, alertDays: alertDays) ==
            ExpiryStatus.expiringSoon;
  }

  /// Sellable units are at or below the product's reorder level, or
  /// [defaultReorderLevel] when it has none.
  bool isLowStockOn(DateTime today, {required int defaultReorderLevel}) =>
      product.isLowStock(
        sellableUnitsOn(today),
        pharmacyDefault: defaultReorderLevel,
      );

  @override
  List<Object?> get props => [product, batches];
}
