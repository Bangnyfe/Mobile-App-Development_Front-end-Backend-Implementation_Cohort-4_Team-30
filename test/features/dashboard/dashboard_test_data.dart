import 'package:team30_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:team30_app/features/dashboard/domain/entities/recent_sale.dart';

/// Builds a summary for tests; override only the fields a test cares about.
DashboardSummary buildSummary({
  int todaySalesTotal = 284500,
  int yesterdaySalesTotal = 254000,
  int expiredBatchCount = 2,
  List<RecentSale>? recentSales,
}) {
  return DashboardSummary(
    userFirstName: 'Aline',
    todaySalesTotal: todaySalesTotal,
    todaySalesCount: 37,
    yesterdaySalesTotal: yesterdaySalesTotal,
    productCount: 412,
    unitsInStock: 8930,
    lowStockCount: 7,
    expiringWindowDays: 30,
    expiringBatchCount: 5,
    expiringCostValue: 88700,
    expiredBatchCount: expiredBatchCount,
    recentSales:
        recentSales ??
        [
          RecentSale(
            saleId: 'sale-0142',
            receiptNo: '0142',
            createdAt: DateTime(2026, 9, 25, 14, 32),
            itemCount: 3,
            paymentMethod: 'Cash',
            total: 6900,
          ),
        ],
  );
}
