import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/product.dart';
import '../domain/inventory_failure.dart';
import '../domain/repositories/product_repository.dart';
import 'inventory_firestore_guard.dart';

/// Products in `pharmacies/{pharmacyId}/products`. `firestore.rules`
/// decides who may change them; refusals arrive as [InventoryFailure].
class FirestoreProductRepository implements ProductRepository {
  FirestoreProductRepository({
    required this.pharmacyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String pharmacyId;
  final FirebaseFirestore _firestore;

  /// Firestore allows at most 500 writes in one batch.
  static const _maxWritesPerBatch = 500;

  CollectionReference<Map<String, dynamic>> get _products => _firestore
      .collection('pharmacies')
      .doc(pharmacyId)
      .collection('products');

  @override
  Stream<List<Product>> watchProducts() => _products
      .orderBy('name')
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs) Product.fromMap(doc.id, doc.data()),
        ],
      )
      .withInventoryFailures();

  @override
  Stream<Product?> watchProduct(String productId) =>
      _products.doc(productId).snapshots().map((doc) {
        final data = doc.data();
        return data == null ? null : Product.fromMap(doc.id, data);
      }).withInventoryFailures();

  @override
  Future<Product?> getProduct(String productId) => guardInventory(() async {
    final doc = await _products.doc(productId).get();
    final data = doc.data();
    return data == null ? null : Product.fromMap(doc.id, data);
  });

  @override
  Future<Product?> findByBarcode(String barcode) => guardInventory(() async {
    // One equality filter, so Firestore's automatic index is enough.
    final result = await _products
        .where('barcode', isEqualTo: barcode.trim())
        .limit(1)
        .get();
    if (result.docs.isEmpty) return null;
    final doc = result.docs.single;
    return Product.fromMap(doc.id, doc.data());
  });

  @override
  Future<Product> createProduct(Product product) => guardInventory(() async {
    final barcode = product.barcode.trim();
    if (barcode.isNotEmpty && await findByBarcode(barcode) != null) {
      throw const InventoryFailure(InventoryFailure.duplicateBarcode);
    }
    final ref = _products.doc();
    await ref.set({
      ...product.copyWith(barcode: barcode).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return product.copyWith(id: ref.id, barcode: barcode);
  });

  @override
  Future<void> updateProduct(Product product) => guardInventory(() async {
    final barcode = product.barcode.trim();
    if (barcode.isNotEmpty) {
      final existing = await findByBarcode(barcode);
      if (existing != null && existing.id != product.id) {
        throw const InventoryFailure(InventoryFailure.duplicateBarcode);
      }
    }
    final fields = product.copyWith(barcode: barcode).toMap()
      ..remove('createdAt');
    await _products.doc(product.id).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> updatePricing(
    String productId, {
    int? sellingPrice,
    int? reorderLevel,
    bool clearReorderLevel = false,
  }) => guardInventory(() async {
    final changes = <String, Object?>{
      'sellingPrice': ?sellingPrice,
      if (clearReorderLevel)
        'reorderLevel': null
      else
        'reorderLevel': ?reorderLevel,
    };
    if (changes.isEmpty) return;
    await _products.doc(productId).update({
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> deleteProduct(String productId) => guardInventory(() async {
    final product = _products.doc(productId);
    final batches = await product.collection('batches').get();
    final refs = [for (final doc in batches.docs) doc.reference, product];
    // The product goes last, so it is never left without its batches
    // deleted if a later chunk fails.
    for (var i = 0; i < refs.length; i += _maxWritesPerBatch) {
      final writes = _firestore.batch();
      for (final ref in refs.skip(i).take(_maxWritesPerBatch)) {
        writes.delete(ref);
      }
      await writes.commit();
    }
  });
}
