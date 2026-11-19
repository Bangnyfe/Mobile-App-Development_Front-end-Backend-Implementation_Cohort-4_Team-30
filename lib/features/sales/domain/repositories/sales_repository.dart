import '../entities/sale.dart';

/// Source of past sales for Sales history and Sale details.
abstract interface class SalesRepository {
  /// The most recent [limit] sales, newest first.
  ///
  /// Emits again whenever a sale is saved, so the history updates live.
  Stream<List<Sale>> watchSales({int limit = defaultLimit});

  /// One sale, or null if there is no sale with this ID.
  Future<Sale?> getSale(String saleId);

  /// Keeps the history to a sensible number of reads on the free plan.
  static const defaultLimit = 200;
}
