import '../../../settings/domain/entities/app_settings.dart';
import '../entities/dashboard_summary.dart';

/// Source of the Home screen's data.
///
/// Returns a stream so the dashboard updates live when a sale, new batch or
/// stock removal is saved anywhere in the app.
abstract interface class DashboardRepository {
  /// The summary, with low stock and expiring batches worked out using
  /// [settings]' low-stock threshold and expiry alert days.
  Stream<DashboardSummary> watchSummary(AppSettings settings);
}
