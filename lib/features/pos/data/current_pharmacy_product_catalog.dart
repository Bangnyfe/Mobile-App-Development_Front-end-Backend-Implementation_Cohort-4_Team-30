import '../../scanner/domain/entities/found_product.dart';
import '../domain/repositories/product_catalog.dart';

/// Searches whichever pharmacy the signed-in user belongs to.
///
/// Created once for the app, before anyone signs in; checks the current
/// pharmacy on every call, like `CurrentPharmacyProductLookupRepository`.
class CurrentPharmacyProductCatalog implements ProductCatalog {
  /// [pharmacyId] returns the signed-in user's pharmacy ID, and
  /// [forPharmacy] creates the catalog for one pharmacy.
  CurrentPharmacyProductCatalog({
    required this._pharmacyId,
    required this._forPharmacy,
  });

  final String? Function() _pharmacyId;
  final ProductCatalog Function(String pharmacyId) _forPharmacy;

  String? _cachedId;
  ProductCatalog? _cached;

  /// The current pharmacy's catalog, or null without a pharmacy.
  ProductCatalog? get _catalog {
    final id = _pharmacyId();
    if (id == null) return null;
    if (id != _cachedId) {
      _cachedId = id;
      _cached = _forPharmacy(id);
    }
    return _cached;
  }

  @override
  Stream<List<CatalogProduct>> watchProducts() =>
      _catalog?.watchProducts() ?? Stream.value(const []);

  @override
  Future<FoundProduct?> loadProduct(String productId) async =>
      _catalog?.loadProduct(productId);
}
