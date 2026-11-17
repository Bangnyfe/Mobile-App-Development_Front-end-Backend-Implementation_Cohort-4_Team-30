import '../domain/entities/dashboard_summary.dart';
import '../domain/entities/recent_sale.dart';
import '../domain/repositories/dashboard_repository.dart';

/// Temporary repository with the prototype's sample numbers.
///
/// Replace with a Firestore-backed implementation once the shared data
/// layer (products, batches, sales) is merged. The Cubit and UI do not
/// change when that happens.
class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  Stream<DashboardSummary> watchSummary() {
    final today = _clock();
    DateTime at(int hour, int minute) =>
        DateTime(today.year, today.month, today.day, hour, minute);

    return Stream.value(
      DashboardSummary(
        userFirstName: 'Aline',
        todaySalesTotal: 284500,
        todaySalesCount: 37,
        yesterdaySalesTotal: 254000,
        productCount: 412,
        unitsInStock: 8930,
        lowStockCount: 7,
        expiringWindowDays: 30,
        expiringBatchCount: 5,
        expiringCostValue: 88700,
        expiredBatchCount: 2,
        recentSales: [
          RecentSale(
            saleId: 'sale-0142',
            receiptNo: '0142',
            createdAt: at(14, 32),
            itemCount: 3,
            paymentMethod: 'Cash',
            total: 6900,
          ),
          RecentSale(
            saleId: 'sale-0141',
            receiptNo: '0141',
            createdAt: at(14, 5),
            itemCount: 1,
            paymentMethod: 'Mobile Money',
            total: 2500,
          ),
          RecentSale(
            saleId: 'sale-0140',
            receiptNo: '0140',
            createdAt: at(13, 48),
            itemCount: 5,
            paymentMethod: 'Cash',
            total: 18400,
          ),
        ],
      ),
    );
  }
}
