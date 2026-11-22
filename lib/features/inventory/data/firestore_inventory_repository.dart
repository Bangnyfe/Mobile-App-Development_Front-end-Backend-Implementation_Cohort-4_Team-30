import '../domain/entities/batch.dart';
import '../domain/entities/category.dart';
import '../domain/entities/inventory_item.dart';
import '../domain/entities/product.dart';
import '../domain/repositories/batch_repository.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/repositories/inventory_repository.dart';
import '../domain/repositories/product_repository.dart';
import 'combine_latest.dart';
import 'firestore_batch_repository.dart';
import 'firestore_category_repository.dart';
import 'firestore_product_repository.dart';

/// The inventory of one pharmacy, combining its product, batch and
/// category repositories.
///
/// The full list reads every batch with one collection-group query
/// (`watchAllBatches`), which needs the index in `firestore.indexes.json`,
/// instead of one listener per product.
class FirestoreInventoryRepository implements InventoryRepository {
  FirestoreInventoryRepository({
    required this._products,
    required this._batches,
    required this._categories,
  });

  /// The Firestore repositories for [pharmacyId].
  factory FirestoreInventoryRepository.forPharmacy(String pharmacyId) =>
      FirestoreInventoryRepository(
        products: FirestoreProductRepository(pharmacyId: pharmacyId),
        batches: FirestoreBatchRepository(pharmacyId: pharmacyId),
        categories: FirestoreCategoryRepository(pharmacyId: pharmacyId),
      );

  final ProductRepository _products;
  final BatchRepository _batches;
  final CategoryRepository _categories;

  @override
  Stream<List<InventoryItem>> watchInventory() => combineLatest2(
    _products.watchProducts(),
    _batches.watchAllBatches(),
    inventoryItemsFrom,
  );

  @override
  Stream<InventoryItem?> watchItem(String productId) => combineLatest2(
    _products.watchProduct(productId),
    _batches.watchBatches(productId),
    (product, batches) => product == null
        ? null
        : InventoryItem(product: product, batches: batches),
  );

  @override
  Stream<List<ProductCategory>> watchCategories() =>
      _categories.watchCategories();

  @override
  Future<Product?> findByBarcode(String barcode) =>
      _products.findByBarcode(barcode);

  @override
  Future<Product> registerProduct(Product product) =>
      _products.createProduct(product);

  @override
  Future<ProductCategory> addCategory(String name) =>
      _categories.addCategory(name);

  @override
  Future<Batch> addBatch(Batch batch) => _batches.addBatch(batch);

  @override
  Future<void> updatePricing(
    String productId, {
    required int sellingPrice,
    int? reorderLevel,
  }) => _products.updatePricing(
    productId,
    sellingPrice: sellingPrice,
    reorderLevel: reorderLevel,
    clearReorderLevel: reorderLevel == null,
  );

  @override
  Future<void> deleteProduct(String productId) =>
      _products.deleteProduct(productId);

  @override
  Future<void> deleteBatch({
    required String productId,
    required String batchId,
  }) => _batches.deleteBatch(productId: productId, batchId: batchId);
}

/// Gives each product its own batches, keeping the products' order and
/// the batches' order (earliest expiry first). Batches whose product no
/// longer exists are left out.
List<InventoryItem> inventoryItemsFrom(
  List<Product> products,
  List<Batch> batches,
) {
  final byProduct = <String, List<Batch>>{};
  for (final batch in batches) {
    (byProduct[batch.productId] ??= []).add(batch);
  }
  return [
    for (final product in products)
      InventoryItem(
        product: product,
        batches: byProduct[product.id] ?? const [],
      ),
  ];
}
