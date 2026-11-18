import 'package:equatable/equatable.dart';

import 'batch_allocation.dart';
import 'pos_batch.dart';
import 'pos_product.dart';

/// One cart line: a product, the batch it will be taken from, and a quantity.
class CartItem extends Equatable {
  const CartItem({
    required this.product,
    required this.batch,
    required this.quantity,
    this.availableBatches = const [],
    this.allocations = const [],
  });

  final PosProduct product;
  final PosBatch batch;
  final int quantity;
  final List<PosBatch> availableBatches;
  final List<BatchAllocation> allocations;

  int get unitPrice => product.sellingPrice;
  int get lineTotal => unitPrice * quantity;

  CartItem copyWith({
    int? quantity,
    PosBatch? batch,
    List<PosBatch>? availableBatches,
    List<BatchAllocation>? allocations,
  }) => CartItem(
    product: product,
    batch: batch ?? this.batch,
    quantity: quantity ?? this.quantity,
    availableBatches: availableBatches ?? this.availableBatches,
    allocations: allocations ?? this.allocations,
  );

  @override
  List<Object?> get props => [
    product,
    batch,
    quantity,
    availableBatches,
    allocations,
  ];
}
