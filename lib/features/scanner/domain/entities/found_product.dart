import 'package:equatable/equatable.dart';

import '../../../pos/domain/entities/pos_batch.dart';
import '../../../pos/domain/entities/pos_product.dart';

/// A product found by its barcode, with its batches.
///
/// Uses the point-of-sale types, so a scanned product can go straight into
/// the cart (`CartCubit.addItem`).
class FoundProduct extends Equatable {
  FoundProduct({
    required this.product,
    this.details = '',
    List<PosBatch> batches = const [],
  }) : batches = List.unmodifiable(
         [...batches]..sort((a, b) => a.expiryDate.compareTo(b.expiryDate)),
       );

  final PosProduct product;

  /// Form and pack size, e.g. "Tablets · strip of 10".
  final String details;

  /// Earliest expiry first.
  final List<PosBatch> batches;

  int get totalUnits => batches.fold(0, (sum, batch) => sum + batch.quantity);

  /// Units that can be sold today: in date and in stock.
  int sellableUnitsOn(DateTime today) => batches
      .where((batch) => batch.isSellableOn(today))
      .fold(0, (sum, batch) => sum + batch.quantity);

  /// The batch with this number, e.g. the one a GS1 DataMatrix named.
  PosBatch? batchNumbered(String batchNumber) {
    final wanted = batchNumber.trim().toUpperCase();
    for (final batch in batches) {
      if (batch.batchNumber.trim().toUpperCase() == wanted) return batch;
    }
    return null;
  }

  @override
  List<Object?> get props => [product, details, batches];
}
