import '../domain/entities/batch.dart';
import '../domain/entities/category.dart';
import '../domain/entities/inventory_item.dart';
import '../domain/entities/product.dart';
import '../domain/inventory_failure.dart';
import '../domain/repositories/inventory_repository.dart';

/// The inventory of whichever pharmacy the signed-in user belongs to.
///
/// Like `CurrentPharmacySalesRepository`: the app's repositories are made
/// once, before anyone signs in, so this looks up the pharmacy on every
/// call and hands the work to the repository for it (in the app, a
/// `FirestoreInventoryRepository`).
class CurrentPharmacyInventoryRepository implements InventoryRepository {
  /// [pharmacyId] returns the signed-in user's pharmacy ID, and
  /// [forPharmacy] creates the repository for one pharmacy.
  CurrentPharmacyInventoryRepository({
    required this._pharmacyId,
    required this._forPharmacy,
  });

  final String? Function() _pharmacyId;
  final InventoryRepository Function(String pharmacyId) _forPharmacy;

  String? _cachedId;
  InventoryRepository? _cached;

  static const noPharmacyMessage =
      'Your session has ended. Please sign in again.';

  /// The repository for the current pharmacy. Throws when the user has no
  /// pharmacy (signed out, or not set up yet).
  InventoryRepository get _current {
    final id = _pharmacyId();
    if (id == null) throw const InventoryFailure(noPharmacyMessage);
    if (id != _cachedId) {
      _cachedId = id;
      _cached = _forPharmacy(id);
    }
    return _cached!;
  }

  Stream<T> _watch<T>(Stream<T> Function(InventoryRepository repo) watch) {
    try {
      return watch(_current);
    } on InventoryFailure catch (failure) {
      return Stream.error(failure);
    }
  }

  Future<T> _run<T>(Future<T> Function(InventoryRepository repo) run) async =>
      run(_current);

  @override
  Stream<List<InventoryItem>> watchInventory() =>
      _watch((repo) => repo.watchInventory());

  @override
  Stream<InventoryItem?> watchItem(String productId) =>
      _watch((repo) => repo.watchItem(productId));

  @override
  Stream<List<ProductCategory>> watchCategories() =>
      _watch((repo) => repo.watchCategories());

  @override
  Future<Product?> findByBarcode(String barcode) =>
      _run((repo) => repo.findByBarcode(barcode));

  @override
  Future<Product> registerProduct(Product product) =>
      _run((repo) => repo.registerProduct(product));

  @override
  Future<ProductCategory> addCategory(String name) =>
      _run((repo) => repo.addCategory(name));

  @override
  Future<Batch> addBatch(Batch batch) => _run((repo) => repo.addBatch(batch));

  @override
  Future<void> updatePricing(
    String productId, {
    required int sellingPrice,
    int? reorderLevel,
  }) => _run(
    (repo) => repo.updatePricing(
      productId,
      sellingPrice: sellingPrice,
      reorderLevel: reorderLevel,
    ),
  );

  @override
  Future<void> deleteProduct(String productId) =>
      _run((repo) => repo.deleteProduct(productId));

  @override
  Future<void> deleteBatch({
    required String productId,
    required String batchId,
  }) =>
      _run((repo) => repo.deleteBatch(productId: productId, batchId: batchId));
}
