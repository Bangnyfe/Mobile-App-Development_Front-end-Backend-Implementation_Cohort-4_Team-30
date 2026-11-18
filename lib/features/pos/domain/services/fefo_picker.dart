import '../entities/pos_batch.dart';

/// First-expiry-first-out: suggests which batch a sale should draw from.
class FefoPicker {
  const FefoPicker._();

  /// Returns the sellable batch with the earliest expiry, or null if none.
  /// [today] is passed in so the result never depends on the real clock.
  /// On a tie, the batch that comes first in [batches] wins.
  static PosBatch? pick(List<PosBatch> batches, {required DateTime today}) {
    PosBatch? best;
    for (final batch in batches) {
      if (!batch.isSellableOn(today)) continue;
      if (best == null || batch.expiryDate.isBefore(best.expiryDate)) {
        best = batch;
      }
    }
    return best;
  }
}
