import '../entities/pos_batch.dart';

/// First-expiry-first-out: suggests which batch a sale should draw from.
class FefoPicker {
  const FefoPicker._();

  /// Returns the sellable batch with the earliest expiry, or null if none.
  /// [today] is passed in so the result never depends on the real clock.
  /// On a tie, the batch that comes first in [batches] wins.
  static PosBatch? pick(List<PosBatch> batches, {required DateTime today}) {
    final sorted = sortedSellable(batches, today: today);
    return sorted.isEmpty ? null : sorted.first;
  }

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
