import 'package:cloud_firestore/cloud_firestore.dart';

import '../../pos/domain/entities/pos_batch.dart';
import '../../pos/domain/entities/pos_product.dart';
import '../domain/entities/found_product.dart';

/// Turns a `pharmacies/{pharmacyId}/products/{productId}` document and its
/// `batches` into a [FoundProduct], using the field names from the ERD.
///
/// Batches missing an expiry date or quantity are left out rather than
/// guessed, so they can never be sold by mistake.
FoundProduct foundProductFromFirestore({
  required String productId,
  required Map<String, dynamic> product,
  required Iterable<({String id, Map<String, dynamic> data})> batches,
}) {
  final form = (product['form'] as String?)?.trim() ?? '';
  final packSize = (product['packSize'] as String?)?.trim() ?? '';
  return FoundProduct(
    product: PosProduct(
      id: productId,
      barcode: product['barcode'] as String? ?? '',
      name: product['name'] as String? ?? 'Unnamed product',
      sellingPrice: (product['sellingPrice'] as num?)?.toInt() ?? 0,
    ),
    details: [form, packSize].where((part) => part.isNotEmpty).join(' · '),
    batches: [for (final batch in batches) ?_batch(batch.id, batch.data)],
  );
}

PosBatch? _batch(String id, Map<String, dynamic> data) {
  final expiry = data['expiryDate'];
  final quantity = (data['quantity'] as num?)?.toInt();
  if (expiry is! Timestamp || quantity == null) return null;
  return PosBatch(
    id: id,
    batchNumber: data['batchNumber'] as String? ?? '',
    expiryDate: expiry.toDate(),
    quantity: quantity,
  );
}
