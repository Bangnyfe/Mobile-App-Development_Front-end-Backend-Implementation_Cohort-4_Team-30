import '../../pos/domain/entities/pos_batch.dart';
import '../../pos/domain/entities/pos_product.dart';
import '../domain/entities/found_product.dart';
import '../domain/repositories/product_lookup_repository.dart';

/// Sample products to scan, for widget tests; the app looks barcodes up
/// in Firestore. Uses the same products and batch numbers as the Remove
/// stock samples, with real check digits so the barcodes can be typed.
///
/// Expiry dates are relative to [clock], so there is always an expired
/// batch to see.
class FakeProductLookupRepository implements ProductLookupRepository {
  FakeProductLookupRepository({
    DateTime Function()? clock,
    List<FoundProduct>? products,
  }) : _products = products ?? sampleProducts((clock ?? DateTime.now)());

  final List<FoundProduct> _products;

  /// Makes every lookup throw, to show the error state.
  bool fail = false;

  @override
  Future<FoundProduct?> findByBarcode(String barcode) async {
    if (fail) throw Exception('offline');
    for (final found in _products) {
      if (found.product.barcode == barcode) return found;
    }
    return null;
  }

  static List<FoundProduct> sampleProducts(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime inDays(int days) => today.add(Duration(days: days));

    return [
      FoundProduct(
        product: const PosProduct(
          id: 'p-metronidazole',
          barcode: '6001007012342',
          name: 'Metronidazole 400mg',
          sellingPrice: 1500,
        ),
        details: 'Tablets · strip of 10',
        batches: [
          PosBatch(
            id: 'b-mz2308',
            batchNumber: 'MZ2308',
            expiryDate: inDays(-25),
            quantity: 14,
          ),
          PosBatch(
            id: 'b-mz2410',
            batchNumber: 'MZ2410',
            expiryDate: inDays(510),
            quantity: 9,
          ),
        ],
      ),
      FoundProduct(
        product: const PosProduct(
          id: 'amoxicillin-500',
          barcode: '6001007023454',
          name: 'Amoxicillin 500mg',
          sellingPrice: 4500,
        ),
        details: 'Capsules · box of 21',
        batches: [
          PosBatch(
            id: 'b-amx-2309',
            batchNumber: 'AMX-2309',
            expiryDate: inDays(-12),
            quantity: 40,
          ),
          PosBatch(
            id: 'b-amx-2411',
            batchNumber: 'AMX-2411',
            expiryDate: inDays(200),
            quantity: 120,
          ),
        ],
      ),
      FoundProduct(
        product: const PosProduct(
          id: 'cough-syrup-100',
          barcode: '6001007056780',
          name: 'Cough syrup 100ml',
          sellingPrice: 2500,
        ),
        details: 'Syrup · 100ml bottle',
        batches: [
          PosBatch(
            id: 'b-cs-118',
            batchNumber: 'CS-118',
            expiryDate: inDays(-3),
            quantity: 6,
          ),
        ],
      ),
      FoundProduct(
        product: const PosProduct(
          id: 'p-ibuprofen',
          barcode: '6001007034566',
          name: 'Ibuprofen 400mg',
          sellingPrice: 1200,
        ),
        details: 'Tablets · strip of 10',
        batches: [
          PosBatch(
            id: 'b-ib2209',
            batchNumber: 'IB2209',
            expiryDate: inDays(-10),
            quantity: 6,
          ),
          PosBatch(
            id: 'b-ib2311',
            batchNumber: 'IB2311',
            expiryDate: inDays(200),
            quantity: 40,
          ),
        ],
      ),
      FoundProduct(
        product: const PosProduct(
          id: 'p-paracetamol',
          barcode: '6001007045678',
          name: 'Paracetamol 500mg',
          sellingPrice: 700,
        ),
        details: 'Tablets · strip of 10',
        batches: [
          PosBatch(
            id: 'b-pc2401',
            batchNumber: 'PC2401',
            expiryDate: inDays(300),
            quantity: 120,
          ),
        ],
      ),
    ];
  }
}
