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

    await _firestore.runTransaction((transaction) async {
      final existingSale = await transaction.get(saleRef);
      if (existingSale.exists) return;

      for (final item in request.items) {
        for (final allocation in item.allocations) {
          final batchRef = _firestore
              .collection('pharmacies')
              .doc(request.pharmacyId)
              .collection('products')
              .doc(item.product.id)
              .collection('batches')
              .doc(allocation.batchId);
          final batchSnapshot = await transaction.get(batchRef);
          if (!batchSnapshot.exists) {
            throw const CheckoutException(
              'Checkout failed because a batch is no longer available.',
            );
          }

          final data = batchSnapshot.data();
          final quantity = (data?['quantity'] as num?)?.toInt();
          final expiry = data?['expiryDate'];
          final expiryDate = expiry is Timestamp ? expiry.toDate() : null;
          if (quantity == null ||
              quantity < allocation.quantity ||
              expiryDate == null ||
              _isExpired(expiryDate, DateTime.now())) {
            throw CheckoutException(
              'Insufficient stock. Available: ${quantity ?? 0}, '
              'Requested: ${allocation.quantity}.',
            );
          }

          transaction.update(batchRef, {
            'quantity': quantity - allocation.quantity,
          });
        }
      }

      transaction.set(saleRef, {
        'receiptNo': request.receiptNo,
        'createdAt': FieldValue.serverTimestamp(),
        'soldBy': request.soldBy,
        'paymentMethod': request.paymentMethod,
        'total': request.total,
        'cashReceived': request.cashReceived,
        'change': request.change,
        'items': request.items.expand((item) => _saleItems(item)).toList(),
      });
    });
  }

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
