import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/found_product.dart';
import '../domain/repositories/product_lookup_repository.dart';
import 'product_firestore_mapper.dart';

/// Looks products up in `pharmacies/{pharmacyId}/products` by `barcode`.
///
/// One equality filter, so Firestore's automatic index is enough.
class FirestoreProductLookupRepository implements ProductLookupRepository {
  FirestoreProductLookupRepository({
    required this.pharmacyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String pharmacyId;
  final FirebaseFirestore _firestore;

  @override
  Future<FoundProduct?> findByBarcode(String barcode) async {
    final products = await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('products')
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (products.docs.isEmpty) return null;

    final product = products.docs.single;
    final batches = await product.reference.collection('batches').get();
    return foundProductFromFirestore(
      productId: product.id,
      product: product.data(),
      batches: [
        for (final batch in batches.docs) (id: batch.id, data: batch.data()),
      ],
    );
  }
}
