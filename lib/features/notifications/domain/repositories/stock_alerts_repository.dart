import '../entities/alert_product.dart';

/// Source of the products and batches the alerts are worked out from.
///
/// Returns a stream so the alerts update live when stock is added, sold or
/// removed anywhere in the app.
abstract interface class StockAlertsRepository {
  Stream<List<AlertProduct>> watchStock();
}
