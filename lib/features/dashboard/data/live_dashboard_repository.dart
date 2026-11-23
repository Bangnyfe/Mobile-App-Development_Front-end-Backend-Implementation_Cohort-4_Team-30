import '../../inventory/data/combine_latest.dart';
import '../../inventory/domain/repositories/inventory_repository.dart';
import '../../sales/domain/repositories/sales_repository.dart';
import '../../settings/domain/entities/app_settings.dart';
import '../domain/build_dashboard_summary.dart';
import '../domain/entities/dashboard_summary.dart';
import '../domain/repositories/dashboard_repository.dart';

/// Home worked out from the pharmacy's sales and stock, through the same
/// repositories as Sales history and the Stock tab, so the numbers always
/// agree with them.
///
/// Emits again whenever a sale is saved or stock is added, sold or removed.
/// Today's and yesterday's totals come from the newest
/// [SalesRepository.defaultLimit] sales, plenty for two days in one
/// pharmacy.
class LiveDashboardRepository implements DashboardRepository {
  /// [userName] returns the signed-in user's name, for the greeting.
  LiveDashboardRepository({
    required this._sales,
    required this._inventory,
    required this._userName,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SalesRepository _sales;
  final InventoryRepository _inventory;
  final String? Function() _userName;
  final DateTime Function() _clock;

  @override
  Stream<DashboardSummary> watchSummary(AppSettings settings) => combineLatest2(
    _sales.watchSales(),
    _inventory.watchInventory(),
    (sales, inventory) => buildDashboardSummary(
      userFirstName: firstNameOf(_userName()),
      sales: sales,
      inventory: inventory,
      now: _clock(),
      expiryAlertDays: settings.expiryAlertDays,
      lowStockThreshold: settings.lowStockThreshold,
    ),
  );
}
