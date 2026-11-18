import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/cart_item.dart';
import '../domain/repositories/checkout_repository.dart';

class FirestoreCheckoutRepository implements CheckoutRepository {
  FirestoreCheckoutRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> checkout(CheckoutRequest request) async {
    final pharmacySales = _firestore
        .collection('pharmacies')
        .doc(request.pharmacyId)
        .collection('sales');
    final saleRef = pharmacySales.doc(request.saleId);

    // Firestore requires every read in a transaction to happen before any
    // write, so the work is split into three phases: read everything,
    // validate everything, then write.
    await _firestore.runTransaction((transaction) async {
      // Phase 1: reads.
      final existingSale = await transaction.get(saleRef);
      if (existingSale.exists) return;

      final reads = <_BatchRead>[];
      for (final item in request.items) {
        for (final allocation in item.allocations) {
          final batchRef = _batchRef(
            request.pharmacyId,
            item.product.id,
            allocation.batchId,
          );
          reads.add(
            _BatchRead(
              ref: batchRef,
              snapshot: await transaction.get(batchRef),
              requested: allocation.quantity,
            ),
          );
        }
      }

      // Phase 2: validation. Throwing here aborts the transaction before
      // anything is written.
      final saleItems = request.items.expand(_saleItems).toList();
      final today = DateTime.now();
      final newQuantities = <int>[];
      for (final read in reads) {
        if (!read.snapshot.exists) {
          throw const CheckoutException(
            'Checkout failed because a batch is no longer available.',
          );
        }

        final data = read.snapshot.data();
        final quantity = (data?['quantity'] as num?)?.toInt();
        final expiry = data?['expiryDate'];
        final expiryDate = expiry is Timestamp ? expiry.toDate() : null;
        if (quantity == null ||
            quantity < read.requested ||
            expiryDate == null ||
            _isExpired(expiryDate, today)) {
          throw CheckoutException(
            'Insufficient stock. Available: ${quantity ?? 0}, '
            'Requested: ${read.requested}.',
          );
        }
        newQuantities.add(quantity - read.requested);
      }

      // Phase 3: writes.
      for (var i = 0; i < reads.length; i++) {
        transaction.update(reads[i].ref, {'quantity': newQuantities[i]});
      }

      transaction.set(saleRef, {
        'receiptNo': request.receiptNo,
        'createdAt': FieldValue.serverTimestamp(),
        'soldBy': request.soldBy,
        'paymentMethod': request.paymentMethod,
        'total': request.total,
        'cashReceived': request.cashReceived,
        'change': request.change,
        'items': saleItems,
      });
    });
  }

  DocumentReference<Map<String, dynamic>> _batchRef(
    String pharmacyId,
    String productId,
    String batchId,
  ) => _firestore
      .collection('pharmacies')
      .doc(pharmacyId)
      .collection('products')
      .doc(productId)
      .collection('batches')
      .doc(batchId);

  Iterable<Map<String, Object>> _saleItems(CartItem item) sync* {
    final allocations = item.allocations;
    if (allocations.isEmpty) {
      throw const CheckoutException(
        'Checkout failed because the cart allocation is missing.',
      );
    }

    for (final allocation in allocations) {
      yield {
        'productId': item.product.id,
        'batchId': allocation.batchId,
        'productName': item.product.name,
        'quantity': allocation.quantity,
        'unitPrice': item.unitPrice,
      };
    }
  }

  bool _isExpired(DateTime expiryDate, DateTime today) {
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final day = DateTime(today.year, today.month, today.day);
    return expiry.isBefore(day);
  }
}

/// A batch read in phase 1 of checkout, kept with the quantity to take.
class _BatchRead {
  const _BatchRead({
    required this.ref,
    required this.snapshot,
    required this.requested,
  });

  final DocumentReference<Map<String, dynamic>> ref;
  final DocumentSnapshot<Map<String, dynamic>> snapshot;
  final int requested;
}
