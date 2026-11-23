import '../../inventory/domain/entities/batch.dart';
import '../../inventory/domain/entities/product.dart';
import '../../inventory/domain/repositories/batch_repository.dart';
import '../../inventory/domain/repositories/product_repository.dart';
import '../../scanner/domain/entities/found_product.dart';
import '../domain/entities/pos_batch.dart';
import '../domain/entities/pos_product.dart';
import '../domain/repositories/product_catalog.dart';

/// The Sell tab's [ProductCatalog], read through the inventory's
/// [ProductRepository] and [BatchRepository], so Sell sees exactly the
/// products and batches the Inventory screens manage.
class InventoryProductCatalog implements ProductCatalog {
  const InventoryProductCatalog({
    required this._products,
    required this._batches,
  });

  final ProductRepository _products;
  final BatchRepository _batches;

  @override
  Stream<List<CatalogProduct>> watchProducts() => _products.watchProducts().map(
    (products) => [
      for (final product in products)
        CatalogProduct(
          product: _posProduct(product),
          details: _details(product),
        ),
    ],
  );

  @override
  Future<FoundProduct?> loadProduct(String productId) async {
    final product = await _products.getProduct(productId);
    if (product == null) return null;
    // The current batches, once: Product found shows a snapshot, and
    // checkout re-checks every batch's stock in its transaction anyway.
    final batches = await _batches.watchBatches(productId).first;
    return FoundProduct(
      product: _posProduct(product),
      details: _details(product),
      batches: [for (final batch in batches) _posBatch(batch)],
    );
  }

  static PosProduct _posProduct(Product product) => PosProduct(
    id: product.id,
    barcode: product.barcode,
    name: product.name,
    sellingPrice: product.sellingPrice,
  );

  /// "Tablets · 10 × 10", leaving out whichever part is blank.
  static String _details(Product product) => [
    product.form.trim(),
    product.packSize.trim(),
  ].where((part) => part.isNotEmpty).join(' · ');

  static PosBatch _posBatch(Batch batch) => PosBatch(
    id: batch.id,
    batchNumber: batch.batchNumber,
    expiryDate: batch.expiryDate,
    quantity: batch.quantity,
  );
}
