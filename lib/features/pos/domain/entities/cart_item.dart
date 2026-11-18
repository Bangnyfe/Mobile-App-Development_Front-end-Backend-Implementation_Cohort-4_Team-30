import 'package:equatable/equatable.dart';

import 'pos_batch.dart';
import 'pos_product.dart';

/// One cart line: a product, the batch it will be taken from, and a quantity.
class CartItem extends Equatable {
  const CartItem({
    required this.product,
    required this.batch,
    required this.quantity,
  });

  final PosProduct product;
  final PosBatch batch;
  final int quantity;

  int get unitPrice => product.sellingPrice;
  int get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
    product: product,
    batch: batch,
    quantity: quantity ?? this.quantity,
  );

  @override
  List<Object?> get props => [product, batch, quantity];
}
