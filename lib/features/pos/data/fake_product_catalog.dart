import '../../scanner/data/fake_product_lookup_repository.dart';
import '../../scanner/domain/entities/found_product.dart';
import '../domain/repositories/product_catalog.dart';

/// The sample products, searchable by name, for widget tests. The same
/// products `FakeProductLookupRepository` finds by barcode.
class FakeProductCatalog implements ProductCatalog {
  FakeProductCatalog({DateTime Function()? clock, List<FoundProduct>? products})
    : _products = [
        ...products ??
            FakeProductLookupRepository.sampleProducts(
              (clock ?? DateTime.now)(),
            ),
      ]..sort((a, b) => a.product.name.compareTo(b.product.name));

  final List<FoundProduct> _products;

  /// Makes every call fail, to show the error state.
  bool fail = false;

  @override
  Stream<List<CatalogProduct>> watchProducts() {
    if (fail) return Stream.error(Exception('offline'));
    return Stream.value([
      for (final found in _products)
        CatalogProduct(product: found.product, details: found.details),
    ]);
  }

  @override
  Future<FoundProduct?> loadProduct(String productId) async {
    if (fail) throw Exception('offline');
    for (final found in _products) {
      if (found.product.id == productId) return found;
    }
    return null;
  }
}
