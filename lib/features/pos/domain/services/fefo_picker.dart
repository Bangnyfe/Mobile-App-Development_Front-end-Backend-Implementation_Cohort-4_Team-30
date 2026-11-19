import '../entities/pos_batch.dart';

/// First-expiry-first-out: suggests which batch a sale should draw from.
class FefoPicker {
  const FefoPicker._();

  /// Returns the sellable batch with the earliest expiry, or null if none.
  /// [today] is passed in so the result never depends on the real clock.
  /// Ties are broken as in [sortedSellable], so the order of [batches]
  /// doesn't matter.
  static PosBatch? pick(List<PosBatch> batches, {required DateTime today}) {
    final sorted = sortedSellable(batches, today: today);
    return sorted.isEmpty ? null : sorted.first;
  }

  /// Sellable batches (in stock, not expired) sorted by expiry day, earliest
  /// first. Time of day is ignored. Batches expiring on the same day are
  /// ordered by batch number, then id, so the result is always the same.
  static List<PosBatch> sortedSellable(
    List<PosBatch> batches, {
    required DateTime today,
  }) {
    final sellable = batches
        .where((batch) => batch.isSellableOn(today))
        .toList();

    sellable.sort((a, b) {
      final expiryComparison = _calendarDay(a.expiryDate)
          .compareTo(_calendarDay(b.expiryDate));
      if (expiryComparison != 0) return expiryComparison;

      final batchNumberComparison = a.batchNumber.compareTo(b.batchNumber);
      if (batchNumberComparison != 0) return batchNumberComparison;
      return a.id.compareTo(b.id);
    });

    return sellable;
  }

  static DateTime _calendarDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
