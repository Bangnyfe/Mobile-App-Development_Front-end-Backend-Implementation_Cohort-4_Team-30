import '../entities/batch.dart';

/// Batches of one pharmacy, at
/// `pharmacies/{pharmacyId}/products/{productId}/batches`.
///
/// Methods throw `InventoryFailure` with a message ready to show.
abstract interface class BatchRepository {
  /// One product's batches, earliest expiry first.
  Stream<List<Batch>> watchBatches(String productId);

  /// Every batch in the pharmacy, earliest expiry first, through a
  /// collection-group query on `pharmacyId` + `expiryDate`.
  ///
  /// Needs the composite index in `firestore.indexes.json`.
  Stream<List<Batch>> watchAllBatches();

  /// Receives a new batch of [productId] and returns it with its new ID.
  /// `pharmacyId` and `productId` are always set by the repository, and
  /// `receivedAt` to the server time.
  Future<Batch> addBatch(Batch batch);

  /// Sets the units in stock. The only change pharmacists may make to an
  /// existing batch.
  Future<void> updateQuantity({
    required String productId,
    required String batchId,
    required int quantity,
  });

  /// Owner only.
  Future<void> deleteBatch({
    required String productId,
    required String batchId,
  });
}
