import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/batch.dart';
import '../domain/repositories/batch_repository.dart';
import 'inventory_firestore_guard.dart';

/// Batches in `pharmacies/{pharmacyId}/products/{productId}/batches`.
///
/// Every batch written here stores this repository's [pharmacyId] and its
/// parent product's ID, whatever the [Batch] passed in says, so the
/// collection-group query in [watchAllBatches] always finds it.
class FirestoreBatchRepository implements BatchRepository {
  FirestoreBatchRepository({
    required this.pharmacyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String pharmacyId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _batches(String productId) =>
      _firestore
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('products')
          .doc(productId)
          .collection('batches');

  @override
  Stream<List<Batch>> watchBatches(String productId) => _batches(productId)
      .orderBy('expiryDate')
      .snapshots()
      .map(_toBatches)
      .withInventoryFailures();

  @override
  Stream<List<Batch>> watchAllBatches() => _firestore
      .collectionGroup('batches')
      .where('pharmacyId', isEqualTo: pharmacyId)
      .orderBy('expiryDate')
      .snapshots()
      .map(_toBatches)
      .withInventoryFailures();

  @override
  Future<Batch> addBatch(Batch batch) => guardInventory(() async {
    if (batch.productId.isEmpty) {
      throw ArgumentError.value(batch.productId, 'productId', 'is required');
    }
    final ref = _batches(batch.productId).doc();
    final saved = batch.copyWith(id: ref.id, pharmacyId: pharmacyId);
    await ref.set({
      ...saved.toMap(),
      'receivedAt': FieldValue.serverTimestamp(),
    });
    return saved;
  });

  @override
  Future<void> updateQuantity({
    required String productId,
    required String batchId,
    required int quantity,
  }) => guardInventory(
    () => _batches(productId).doc(batchId).update({'quantity': quantity}),
  );

  @override
  Future<void> deleteBatch({
    required String productId,
    required String batchId,
  }) => guardInventory(() => _batches(productId).doc(batchId).delete());

  /// Batches without an expiry date are left out, see [Batch.fromMap].
  List<Batch> _toBatches(QuerySnapshot<Map<String, dynamic>> snapshot) => [
    for (final doc in snapshot.docs) ?Batch.fromMap(doc.id, doc.data()),
  ];
}
