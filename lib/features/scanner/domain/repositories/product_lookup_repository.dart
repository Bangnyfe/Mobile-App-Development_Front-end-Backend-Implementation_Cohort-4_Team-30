import '../entities/found_product.dart';

/// Finds a product of the signed-in pharmacy by its barcode.
abstract interface class ProductLookupRepository {
  /// The product whose `barcode` is [barcode] (as normalised by
  /// `Gs1Parser`), with its batches, or null if the pharmacy has none.
  ///
  /// Throws if the lookup itself fails, for example when offline.
  Future<FoundProduct?> findByBarcode(String barcode);
}
