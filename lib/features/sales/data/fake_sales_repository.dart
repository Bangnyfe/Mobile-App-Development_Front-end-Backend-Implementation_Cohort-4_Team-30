import '../domain/entities/sale.dart';
import '../domain/repositories/sales_repository.dart';

/// Temporary repository with sample sales, used until auth gives us the
/// signed-in user's pharmacy ID for the Firestore repository.
///
/// Today's three sales match the dashboard's sample "Recent transactions",
/// so tapping one there opens the same sale here.
class FakeSalesRepository implements SalesRepository {
  FakeSalesRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  Stream<List<Sale>> watchSales({
    int limit = SalesRepository.defaultLimit,
  }) => Stream.value(_sales().take(limit).toList());

  @override
  Future<Sale?> getSale(String saleId) async {
    for (final sale in _sales()) {
      if (sale.id == saleId) return sale;
    }
    return null;
  }

  /// Newest first, like Firestore returns them.
  List<Sale> _sales() {
    final now = _clock();
    DateTime at(int daysAgo, int hour, int minute) =>
        DateTime(now.year, now.month, now.day - daysAgo, hour, minute);

    return [
      Sale(
        id: 'sale-0142',
        receiptNo: '0142',
        createdAt: at(0, 14, 32),
        soldBy: 'u1',
        soldByName: 'Aline Uwase',
        paymentMethod: 'Cash',
        total: 6900,
        cashReceived: 10000,
        change: 3100,
        lines: const [
          SaleLine(
            productId: 'p-paracetamol',
            batchId: 'b-para-1',
            productName: 'Paracetamol 500mg',
            quantity: 2,
            unitPrice: 1200,
          ),
          SaleLine(
            productId: 'p-amoxicillin',
            batchId: 'b-amox-1',
            productName: 'Amoxicillin 250mg',
            quantity: 1,
            unitPrice: 4500,
          ),
        ],
      ),
      Sale(
        id: 'sale-0141',
        receiptNo: '0141',
        createdAt: at(0, 14, 5),
        soldBy: 'u2',
        soldByName: 'Eric Mugisha',
        paymentMethod: 'Mobile Money',
        total: 2500,
        cashReceived: 2500,
        change: 0,
        lines: const [
          SaleLine(
            productId: 'p-ors',
            batchId: 'b-ors-1',
            productName: 'ORS sachets',
            quantity: 1,
            unitPrice: 2500,
          ),
        ],
      ),
      Sale(
        id: 'sale-0140',
        receiptNo: '0140',
        createdAt: at(0, 13, 48),
        soldBy: 'u3',
        soldByName: 'Diane Ingabire',
        paymentMethod: 'Cash',
        total: 18400,
        cashReceived: 20000,
        change: 1600,
        lines: const [
          // Two batches of one product: FEFO finished the older batch first.
          SaleLine(
            productId: 'p-ibuprofen',
            batchId: 'b-ibu-1',
            productName: 'Ibuprofen 400mg',
            quantity: 1,
            unitPrice: 1500,
          ),
          SaleLine(
            productId: 'p-ibuprofen',
            batchId: 'b-ibu-2',
            productName: 'Ibuprofen 400mg',
            quantity: 1,
            unitPrice: 1500,
          ),
          SaleLine(
            productId: 'p-metformin',
            batchId: 'b-met-1',
            productName: 'Metformin 500mg',
            quantity: 1,
            unitPrice: 6400,
          ),
          SaleLine(
            productId: 'p-vitc',
            batchId: 'b-vitc-1',
            productName: 'Vitamin C 1000mg',
            quantity: 2,
            unitPrice: 4500,
          ),
        ],
      ),
      Sale(
        id: 'sale-0139',
        receiptNo: '0139',
        createdAt: at(1, 18, 10),
        soldBy: 'u1',
        soldByName: 'Aline Uwase',
        paymentMethod: 'Card',
        total: 12000,
        cashReceived: 12000,
        change: 0,
        lines: const [
          SaleLine(
            productId: 'p-salbutamol',
            batchId: 'b-salb-1',
            productName: 'Salbutamol inhaler',
            quantity: 1,
            unitPrice: 12000,
          ),
        ],
      ),
      Sale(
        id: 'sale-0138',
        receiptNo: '0138',
        createdAt: at(1, 9, 15),
        soldBy: 'u2',
        soldByName: 'Eric Mugisha',
        paymentMethod: 'Cash',
        total: 3600,
        cashReceived: 5000,
        change: 1400,
        lines: const [
          SaleLine(
            productId: 'p-cetirizine',
            batchId: 'b-cet-1',
            productName: 'Cetirizine 10mg',
            quantity: 3,
            unitPrice: 1200,
          ),
        ],
      ),
      Sale(
        id: 'sale-0137',
        receiptNo: '0137',
        createdAt: at(2, 16, 40),
        soldBy: 'u3',
        soldByName: 'Diane Ingabire',
        paymentMethod: 'Mobile Money',
        total: 9000,
        cashReceived: 9000,
        change: 0,
        lines: const [
          SaleLine(
            productId: 'p-omeprazole',
            batchId: 'b-ome-1',
            productName: 'Omeprazole 20mg',
            quantity: 2,
            unitPrice: 4500,
          ),
        ],
      ),
    ];
  }
}
