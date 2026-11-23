import '../entities/batch.dart';
import '../entities/category.dart';
import '../entities/inventory_item.dart';
import '../entities/product.dart';

/// Everything the Inventory, Register product and Add stock screens need,
/// for the signed-in user's pharmacy.
///
/// The Firestore version combines the product, batch and category
/// repositories. Methods throw `InventoryFailure` with a message ready to
/// show, and streams emit it as an error.
abstract interface class InventoryRepository {
  /// Every product with its batches, sorted by name. Emits again on every
  /// change, from this phone or another.
  Stream<List<InventoryItem>> watchInventory();

  /// One product with its batches, live. Emits null once it is deleted.
  Stream<InventoryItem?> watchItem(String productId);

  /// Every category, sorted by name.
  Stream<List<ProductCategory>> watchCategories();

  /// The product registered with [barcode], or null.
  Future<Product?> findByBarcode(String barcode);

  /// Saves a new product and returns it with its new ID.
  ///
  /// Throws `InventoryFailure.duplicateBarcode` if the barcode is taken.
  Future<Product> registerProduct(Product product);

  Future<ProductCategory> addCategory(String name);

  /// Receives a new batch and returns it with its new ID.
  Future<Batch> addBatch(Batch batch);

  /// Owner only. A null [reorderLevel] goes back to the pharmacy default.
  Future<void> updatePricing(
    String productId, {
    required int sellingPrice,
    int? reorderLevel,
  });

  /// Owner only: deletes the product and all of its batches.
  Future<void> deleteProduct(String productId);

  /// Owner only.
  Future<void> deleteBatch({
    required String productId,
    required String batchId,
  });
}
