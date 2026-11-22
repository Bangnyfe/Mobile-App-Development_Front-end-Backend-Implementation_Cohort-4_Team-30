import '../entities/category.dart';

/// Categories of one pharmacy, at `pharmacies/{pharmacyId}/categories`.
///
/// Methods throw `InventoryFailure` with a message ready to show.
abstract interface class CategoryRepository {
  /// Every category, sorted by name.
  Stream<List<ProductCategory>> watchCategories();

  /// Saves a new category and returns it with its new ID.
  Future<ProductCategory> addCategory(String name);

  /// Owner only.
  Future<void> renameCategory(String categoryId, String name);

  /// Owner only. Products keep the old `categoryId` until edited.
  Future<void> deleteCategory(String categoryId);
}
