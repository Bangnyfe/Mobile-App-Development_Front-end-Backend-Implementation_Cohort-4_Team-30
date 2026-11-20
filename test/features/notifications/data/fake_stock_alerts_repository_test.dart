import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/notifications/data/fake_stock_alerts_repository.dart';
import 'package:team30_app/features/notifications/domain/build_stock_alerts.dart';
import 'package:team30_app/features/notifications/domain/entities/stock_alert.dart';
import 'package:team30_app/features/settings/domain/entities/app_settings.dart';

void main() {
  test(
    'sample stock gives every kind of alert with default settings',
    () async {
      final today = DateTime(2026, 11, 20, 9);
      final products = await FakeStockAlertsRepository(clock: () => today)
          .watchStock()
          .first;

      final alerts = buildStockAlerts(
        products,
        today: today,
        lowStockThreshold: AppSettings.defaultLowStockThreshold,
        expiryAlertDays: AppSettings.defaultExpiryAlertDays,
      );

      expect(alerts.map((a) => (a.type, a.productName)), [
        (StockAlertType.expired, 'Amoxicillin 500mg'),
        (StockAlertType.expired, 'Cough syrup 100ml'),
        (StockAlertType.expiringSoon, 'Paracetamol 500mg'),
        (StockAlertType.expiringSoon, 'ORS sachets'),
        (StockAlertType.lowStock, 'Cough syrup 100ml'),
        (StockAlertType.lowStock, 'Metformin 500mg'),
        (StockAlertType.lowStock, 'Insulin glargine 100IU/ml'),
        (StockAlertType.lowStock, 'Ibuprofen 200mg'),
      ]);
    },
  );
}
