import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/removable_product.dart';
import '../domain/entities/stock_removal.dart';
import '../domain/removal_rules.dart';
import '../domain/repositories/stock_removal_repository.dart';
import 'stock_removal_firestore_mapper.dart';

/// [StockRemovalRepository] for one pharmacy, on Firestore.
///
/// Reads `pharmacies/{pharmacyId}/products/{productId}/batches` and writes
/// `pharmacies/{pharmacyId}/stock_removals`. The signed-in user is read on
/// each removal, so the record names whoever actually removed the stock.
class FirestoreStockRemovalRepository implements StockRemovalRepository {
  FirestoreStockRemovalRepository({
    required this.pharmacyId,
    required this._removedBy,
    required this._removedByName,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String pharmacyId;

  /// The signed-in user's uid.
  final String Function() _removedBy;

  /// The signed-in user's name, saved as a snapshot.
  final String Function() _removedByName;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _pharmacy =>
      _firestore.collection('pharmacies').doc(pharmacyId);

  @override
  Future<List<RemovableProduct>> loadProducts() => _guard(() async {
    final productDocs = await _pharmacy
        .collection(StockRemovalFields.products)
        .get();
    final products = <RemovableProduct>[];
    for (final productDoc in productDocs.docs) {
      final batchDocs = await productDoc.reference
          .collection(StockRemovalFields.batches)
          .get();
      final batches = <RemovableBatch>[];
      for (final batchDoc in batchDocs.docs) {
        final batch = batchFromFirestore(batchDoc.id, batchDoc.data());
        if (batch != null && batch.quantity > 0) batches.add(batch);
      }
      if (batches.isEmpty) continue;
      products.add(
        productFromFirestore(productDoc.id, productDoc.data(), batches),
      );
    }
    products.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return products;
  });

  @override
  Future<StockRemoval> removeStock(StockRemovalRequest request) {
    final reasonProblem = RemovalRules.reason(request.reason, request.note);
    if (reasonProblem != null) {
      return Future.error(StockRemovalFailure(reasonProblem));
    }

    return _guard(() {
      final productRef = _pharmacy
          .collection(StockRemovalFields.products)
          .doc(request.productId);
      final batchRef = productRef
          .collection(StockRemovalFields.batches)
          .doc(request.batchId);
      final removalRef = _pharmacy
          .collection(StockRemovalFields.stockRemovals)
          .doc();
      final removedBy = _removedBy();
      final removedByName = _removedByName();

      return _firestore.runTransaction<StockRemoval>((transaction) async {
        // Firestore requires every read in a transaction before any write.
        final productSnapshot = await transaction.get(productRef);
        final batchSnapshot = await transaction.get(batchRef);
        final productData = productSnapshot.data();
        final batchData = batchSnapshot.data();
        if (productData == null || batchData == null) {
          throw const StockRemovalFailure('This batch no longer exists.');
        }
        final batch = batchFromFirestore(batchSnapshot.id, batchData);
        if (batch == null) {
          throw const StockRemovalFailure('This batch record is incomplete.');
        }

        // Checked against the stock as it is now, not as the screen loaded
        // it, so units sold meanwhile can't be removed as well.
        final quantityProblem = RemovalRules.quantity(
          request.quantity,
          available: batch.quantity,
        );
        if (quantityProblem != null) {
          throw StockRemovalFailure(quantityProblem);
        }

        final productName =
            productData[StockRemovalFields.name] as String? ?? '';
        final costValue = batch.costOf(request.quantity);

        transaction.update(batchRef, {
          StockRemovalFields.quantity: batch.quantity - request.quantity,
        });
        transaction.set(
          removalRef,
          removalToFirestore(
            request: request,
            productName: productName,
            batchNumber: batch.batchNumber,
            costValue: costValue,
            removedBy: removedBy,
            removedByName: removedByName,
          ),
        );

        return StockRemoval(
          id: removalRef.id,
          productId: request.productId,
          productName: productName,
          batchId: request.batchId,
          batchNumber: batch.batchNumber,
          quantity: request.quantity,
          reason: request.reason,
          note: request.note.trim(),
          costValue: costValue,
          removedBy: removedBy,
          removedByName: removedByName,
          createdAt: DateTime.now(),
        );
      });
    });
  }

  /// Runs [action] and turns Firestore errors into [StockRemovalFailure].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on StockRemovalFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw StockRemovalFailure(stockRemovalErrorMessage(error.code));
    }
  }
}
