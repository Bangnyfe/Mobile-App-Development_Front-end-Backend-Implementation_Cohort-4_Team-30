import '../domain/entities/alert_product.dart';
import '../domain/repositories/stock_alerts_repository.dart';

/// Sample products, so every kind of alert shows in widget tests. The app
/// works the alerts out from the signed-in pharmacy's inventory.
class FakeStockAlertsRepository implements StockAlertsRepository {
  FakeStockAlertsRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  Stream<List<AlertProduct>> watchStock() {
    final now = _clock();
    DateTime inDays(int days) => DateTime(now.year, now.month, now.day + days);

    return Stream.value([
      AlertProduct(
        id: 'amoxicillin-500',
        name: 'Amoxicillin 500mg',
        reorderLevel: 30,
        batches: [
          AlertBatch(
            id: 'b-amx-2309',
            batchNumber: 'AMX-2309',
            expiryDate: inDays(-12),
            quantity: 40,
          ),
          AlertBatch(
            id: 'b-amx-2411',
            batchNumber: 'AMX-2411',
            expiryDate: inDays(200),
            quantity: 120,
          ),
        ],
      ),
      // Expired and nothing else on the shelf, so also out of stock.
      AlertProduct(
        id: 'cough-syrup-100',
        name: 'Cough syrup 100ml',
        batches: [
          AlertBatch(
            id: 'b-cs-118',
            batchNumber: 'CS-118',
            expiryDate: inDays(-3),
            quantity: 6,
          ),
        ],
      ),
      AlertProduct(
        id: 'paracetamol-500',
        name: 'Paracetamol 500mg',
        reorderLevel: 50,
        batches: [
          AlertBatch(
            id: 'b-pcm-2402',
            batchNumber: 'PCM-2402',
            expiryDate: inDays(19),
            quantity: 80,
          ),
          AlertBatch(
            id: 'b-pcm-2410',
            batchNumber: 'PCM-2410',
            expiryDate: inDays(300),
            quantity: 400,
          ),
        ],
      ),
      AlertProduct(
        id: 'ors-sachets',
        name: 'ORS sachets',
        reorderLevel: 20,
        batches: [
          AlertBatch(
            id: 'b-ors-77',
            batchNumber: 'ORS-77',
            expiryDate: inDays(45),
            quantity: 60,
          ),
        ],
      ),
      AlertProduct(
        id: 'ibuprofen-200',
        name: 'Ibuprofen 200mg',
        reorderLevel: 25,
        batches: [
          AlertBatch(
            id: 'b-ibu-551',
            batchNumber: 'IBU-551',
            expiryDate: inDays(250),
            quantity: 12,
          ),
        ],
      ),
      AlertProduct(
        id: 'insulin-glargine',
        name: 'Insulin glargine 100IU/ml',
        reorderLevel: 10,
        batches: [
          AlertBatch(
            id: 'b-ins-09',
            batchNumber: 'INS-09',
            expiryDate: inDays(150),
            quantity: 4,
          ),
        ],
      ),
      AlertProduct(
        id: 'vitamin-c-500',
        name: 'Vitamin C 500mg',
        batches: [
          AlertBatch(
            id: 'b-vc-31',
            batchNumber: 'VC-31',
            expiryDate: inDays(400),
            quantity: 300,
          ),
        ],
      ),
      const AlertProduct(
        id: 'metformin-500',
        name: 'Metformin 500mg',
        reorderLevel: 40,
      ),
    ]);
  }
}
