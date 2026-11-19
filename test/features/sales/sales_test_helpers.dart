import 'package:team30_app/features/sales/domain/entities/sale.dart';
import 'package:team30_app/features/sales/domain/repositories/sales_repository.dart';

/// Repository whose sales and failures the test controls.
class StubSalesRepository implements SalesRepository {
  StubSalesRepository({this.sales = const [], this.fail = false});

  List<Sale> sales;
  bool fail;

  @override
  Stream<List<Sale>> watchSales({int limit = SalesRepository.defaultLimit}) =>
      fail ? Stream.error(Exception('offline')) : Stream.value(sales);

  @override
  Future<Sale?> getSale(String saleId) async {
    if (fail) throw Exception('offline');
    for (final sale in sales) {
      if (sale.id == saleId) return sale;
    }
    return null;
  }
}

/// A one-line cash sale; override only what a test cares about.
Sale buildSale({
  String id = 's1',
  String receiptNo = '0001',
  required DateTime createdAt,
  int total = 1000,
}) => Sale(
  id: id,
  receiptNo: receiptNo,
  createdAt: createdAt,
  soldBy: 'u1',
  soldByName: 'Aline Uwase',
  paymentMethod: 'Cash',
  total: total,
  cashReceived: total,
  change: 0,
  lines: [
    SaleLine(
      productId: 'p1',
      batchId: 'b1',
      productName: 'Paracetamol 500mg',
      quantity: 1,
      unitPrice: total,
    ),
  ],
);
