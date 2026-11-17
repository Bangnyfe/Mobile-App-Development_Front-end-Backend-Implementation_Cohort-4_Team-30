import '../entities/dashboard_summary.dart';

/// Source of the Home screen's data.
///
/// Returns a stream so the dashboard updates live when a sale, new batch or
/// stock removal is saved anywhere in the app.
abstract interface class DashboardRepository {
  Stream<DashboardSummary> watchSummary();
}
