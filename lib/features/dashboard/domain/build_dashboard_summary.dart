import '../../../core/utils/expiry_status.dart';
import '../../inventory/domain/entities/inventory_item.dart';
import '../../sales/domain/entities/sale.dart';
import 'entities/dashboard_summary.dart';
import 'entities/recent_sale.dart';

/// How many sales "Recent transactions" lists.
const recentSaleCount = 5;

/// Works out everything Home shows from the pharmacy's [sales] (newest
/// first) and [inventory], at [now].
///
/// - **Sales**: today's and yesterday's totals by calendar day, and the
///   [recentSaleCount] newest sales.
/// - **Stock**: units that can still be sold, so expired units never make
///   stock look healthier than it is. Low stock compares those units with
///   each product's reorder level, or [lowStockThreshold] without one, like
///   the Stock tab.
/// - **Expiry**: batches with units left that expire within
///   [expiryAlertDays] (a batch expiring today counts here), with their
///   value at cost, and batches past their expiry date still on the shelf.
DashboardSummary buildDashboardSummary({
  required String userFirstName,
  required List<Sale> sales,
  required List<InventoryItem> inventory,
  required DateTime now,
  required int expiryAlertDays,
  required int lowStockThreshold,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  bool isOn(DateTime day, DateTime time) =>
      time.year == day.year && time.month == day.month && time.day == day.day;

  var todayTotal = 0;
  var todayCount = 0;
  var yesterdayTotal = 0;
  for (final sale in sales) {
    if (isOn(today, sale.createdAt)) {
      todayTotal += sale.total;
      todayCount++;
    } else if (isOn(yesterday, sale.createdAt)) {
      yesterdayTotal += sale.total;
    }
  }

  var units = 0;
  var lowStock = 0;
  var expiringBatches = 0;
  var expiringValue = 0;
  var expiredBatches = 0;
  for (final item in inventory) {
    units += item.sellableUnitsOn(today);
    if (item.isLowStockOn(today, defaultReorderLevel: lowStockThreshold)) {
      lowStock++;
    }
    for (final batch in item.batchesInStock) {
      switch (expiryStatusFor(
        batch.expiryDate,
        today: today,
        alertDays: expiryAlertDays,
      )) {
        case ExpiryStatus.expired:
          expiredBatches++;
        case ExpiryStatus.expiringSoon:
          expiringBatches++;
          expiringValue += batch.stockValue;
        case ExpiryStatus.inDate:
          break;
      }
    }
  }

  return DashboardSummary(
    userFirstName: userFirstName,
    todaySalesTotal: todayTotal,
    todaySalesCount: todayCount,
    yesterdaySalesTotal: yesterdayTotal,
    productCount: inventory.length,
    unitsInStock: units,
    lowStockCount: lowStock,
    expiringWindowDays: expiryAlertDays,
    expiringBatchCount: expiringBatches,
    expiringCostValue: expiringValue,
    expiredBatchCount: expiredBatches,
    recentSales: [
      for (final sale in sales.take(recentSaleCount))
        RecentSale(
          saleId: sale.id,
          receiptNo: sale.receiptNo,
          createdAt: sale.createdAt,
          itemCount: sale.itemCount,
          paymentMethod: sale.paymentMethod,
          total: sale.total,
        ),
    ],
  );
}

/// The first word of [name], for "Good morning, Aline". Empty if there is
/// no name.
String firstNameOf(String? name) {
  final words = name?.trim().split(RegExp(r'\s+')) ?? const [];
  return words.isEmpty ? '' : words.first;
}
