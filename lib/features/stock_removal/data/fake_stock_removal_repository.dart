import '../domain/entities/removable_product.dart';
import '../domain/entities/stock_removal.dart';
import '../domain/removal_rules.dart';
import '../domain/repositories/stock_removal_repository.dart';

/// In-memory stock with the prototype's sample products, used until the
/// shared data layer (products and batches in Firestore) is merged.
///
/// Expiry dates are set relative to [clock], so the samples always include
/// an expired batch, one expiring soon and some in date.
class FakeStockRemovalRepository implements StockRemovalRepository {
  FakeStockRemovalRepository({
    DateTime Function()? clock,
    List<RemovableProduct>? products,
  }) : _clock = clock ?? DateTime.now {
    _products = products ?? _sampleProducts(_clock());
  }

  final DateTime Function() _clock;
  late List<RemovableProduct> _products;
  final List<StockRemoval> _removals = [];

  /// Every removal recorded so far, oldest first.
  List<StockRemoval> get removals => List.unmodifiable(_removals);

  @override
  Future<List<RemovableProduct>> loadProducts() async =>
      _products.where((product) => product.totalUnits > 0).toList();

  @override
  Future<StockRemoval> removeStock(StockRemovalRequest request) async {
    final productIndex = _products.indexWhere(
      (product) => product.id == request.productId,
    );
    if (productIndex == -1) {
      throw const StockRemovalFailure('This product no longer exists.');
    }
    final product = _products[productIndex];
    final batch = product.batchById(request.batchId);
    if (batch == null) {
      throw const StockRemovalFailure('This batch no longer exists.');
    }

    // Checked again here, as the Firestore transaction will, in case the
    // batch changed after the screen loaded.
    final problem =
        RemovalRules.quantity(request.quantity, available: batch.quantity) ??
        RemovalRules.reason(request.reason, request.note);
    if (problem != null) throw StockRemovalFailure(problem);

    _products[productIndex] = RemovableProduct(
      id: product.id,
      name: product.name,
      barcode: product.barcode,
      details: product.details,
      batches: [
        for (final b in product.batches)
          b.id == batch.id
              ? b.copyWith(quantity: b.quantity - request.quantity)
              : b,
      ],
    );

    final removal = StockRemoval(
      id: 'removal-${_removals.length + 1}',
      productId: product.id,
      productName: product.name,
      batchId: batch.id,
      batchNumber: batch.batchNumber,
      quantity: request.quantity,
      reason: request.reason,
      note: request.note.trim(),
      costValue: batch.costOf(request.quantity),
      removedBy: 'Aline Uwase',
      createdAt: _clock(),
    );
    _removals.add(removal);
    return removal;
  }

  static List<RemovableProduct> _sampleProducts(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime inDays(int days) => today.add(Duration(days: days));

    return [
      RemovableProduct(
        id: 'p-metronidazole',
        name: 'Metronidazole 400mg',
        barcode: '6001007012345',
        details: 'Tablets · strip of 10',
        batches: [
          RemovableBatch(
            id: 'b-mz2308',
            batchNumber: 'MZ2308',
            expiryDate: inDays(-25),
            quantity: 14,
            costPrice: 1100,
          ),
          RemovableBatch(
            id: 'b-mz2410',
            batchNumber: 'MZ2410',
            expiryDate: inDays(510),
            quantity: 9,
            costPrice: 1100,
          ),
        ],
      ),
      // Same IDs as Notifications' sample stock, so "Remove stock" on an
      // expiry alert opens this batch while both use sample data.
      RemovableProduct(
        id: 'amoxicillin-500',
        name: 'Amoxicillin 500mg',
        barcode: '6001007023456',
        details: 'Capsules · box of 21',
        batches: [
          RemovableBatch(
            id: 'b-amx-2309',
            batchNumber: 'AMX-2309',
            expiryDate: inDays(-12),
            quantity: 40,
            costPrice: 3500,
          ),
          RemovableBatch(
            id: 'b-amx-2411',
            batchNumber: 'AMX-2411',
            expiryDate: inDays(200),
            quantity: 120,
            costPrice: 3500,
          ),
        ],
      ),
      RemovableProduct(
        id: 'cough-syrup-100',
        name: 'Cough syrup 100ml',
        barcode: '6001007056789',
        details: 'Syrup · 100ml bottle',
        batches: [
          RemovableBatch(
            id: 'b-cs-118',
            batchNumber: 'CS-118',
            expiryDate: inDays(-3),
            quantity: 6,
            costPrice: 1800,
          ),
        ],
      ),
      RemovableProduct(
        id: 'p-ibuprofen',
        name: 'Ibuprofen 400mg',
        barcode: '6001007034567',
        details: 'Tablets · strip of 10',
        batches: [
          RemovableBatch(
            id: 'b-ib2209',
            batchNumber: 'IB2209',
            expiryDate: inDays(-10),
            quantity: 6,
            costPrice: 800,
          ),
          RemovableBatch(
            id: 'b-ib2311',
            batchNumber: 'IB2311',
            expiryDate: inDays(200),
            quantity: 40,
            costPrice: 800,
          ),
        ],
      ),
      RemovableProduct(
        id: 'p-paracetamol',
        name: 'Paracetamol 500mg',
        barcode: '6001007045678',
        details: 'Tablets · strip of 10',
        batches: [
          RemovableBatch(
            id: 'b-pc2401',
            batchNumber: 'PC2401',
            expiryDate: inDays(300),
            quantity: 120,
            costPrice: 450,
          ),
        ],
      ),
    ];
  }
}
