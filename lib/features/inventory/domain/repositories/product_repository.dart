import '../entities/product.dart';

/// Products of one pharmacy, at `pharmacies/{pharmacyId}/products`.
///
/// Methods throw `InventoryFailure` with a message ready to show.
abstract interface class ProductRepository {
  /// Every product, sorted by name. Emits again on every change.
  Stream<List<Product>> watchProducts();

  /// One product, live. Emits null once it is deleted.
  Stream<Product?> watchProduct(String productId);

  Future<Product?> getProduct(String productId);

  Future<Product?> findByBarcode(String barcode);

  /// Saves a new product and returns it with its new ID. The ID, and the
  /// `createdAt`/`updatedAt` on [product], are ignored and set here.
  ///
  /// Throws `InventoryFailure.duplicateBarcode` if the barcode is taken.
  Future<Product> createProduct(Product product);

  /// Owner only: replaces the product's details (not `createdAt`).
  Future<void> updateProduct(Product product);

  /// Owner only: changes the selling price and/or reorder level. Pass
  /// [clearReorderLevel] to go back to the pharmacy default.
  Future<void> updatePricing(
    String productId, {
    int? sellingPrice,
    int? reorderLevel,
    bool clearReorderLevel = false,
  });

  /// Owner only: deletes the product and all of its batches.
  Future<void> deleteProduct(String productId);
}
