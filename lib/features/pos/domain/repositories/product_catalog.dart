import 'package:equatable/equatable.dart';

import '../../../scanner/domain/entities/found_product.dart';
import '../entities/pos_product.dart';

/// A product as listed when searching Sell by name, before its batches are
/// loaded.
class CatalogProduct extends Equatable {
  const CatalogProduct({required this.product, this.details = ''});

  final PosProduct product;

  /// Form and pack size, e.g. "Tablets · 10 × 10".
  final String details;

  @override
  List<Object?> get props => [product, details];
}

/// The pharmacy's products, for finding one to sell by name: the way to
/// sell items without a barcode, or whose barcode won't scan.
abstract interface class ProductCatalog {
  /// Every product, sorted by name. Emits again on every change.
  Stream<List<CatalogProduct>> watchProducts();

  /// [productId] with its batches, ready for Product found; null if the
  /// product no longer exists.
  Future<FoundProduct?> loadProduct(String productId);
}
