import '../domain/entities/found_product.dart';
import '../domain/repositories/product_lookup_repository.dart';

/// Looks barcodes up in whichever pharmacy the signed-in user belongs to.
///
/// Created once for the app, before anyone signs in; checks the current
/// pharmacy on every lookup, like `CurrentPharmacySalesRepository`.
class CurrentPharmacyProductLookupRepository
    implements ProductLookupRepository {
  /// [pharmacyId] returns the signed-in user's pharmacy ID, and
  /// [forPharmacy] creates the repository for one pharmacy.
  CurrentPharmacyProductLookupRepository({
    required this._pharmacyId,
    required this._forPharmacy,
  });

  final String? Function() _pharmacyId;
  final ProductLookupRepository Function(String pharmacyId) _forPharmacy;

  String? _cachedId;
  ProductLookupRepository? _cached;

  @override
  Future<FoundProduct?> findByBarcode(String barcode) async {
    final id = _pharmacyId();
    // Without a pharmacy there are no products to find.
    if (id == null) return null;
    if (id != _cachedId) {
      _cachedId = id;
      _cached = _forPharmacy(id);
    }
    return _cached!.findByBarcode(barcode);
  }
}
