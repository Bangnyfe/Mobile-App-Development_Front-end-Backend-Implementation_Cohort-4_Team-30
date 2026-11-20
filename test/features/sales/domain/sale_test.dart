import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/sales/domain/entities/sale.dart';

void main() {
  Sale sale({String? soldByName, String paymentMethod = 'Cash'}) => Sale(
    id: 's1',
    receiptNo: '0142',
    createdAt: DateTime(2026, 11, 19, 10, 30),
    soldBy: 'uid-eric',
    soldByName: soldByName,
    paymentMethod: paymentMethod,
    total: 4500,
    cashReceived: 5000,
    change: 500,
    lines: const [
      SaleLine(
        productId: 'p1',
        batchId: 'b1',
        productName: 'Paracetamol 500mg',
        quantity: 2,
        unitPrice: 1000,
      ),
      SaleLine(
        productId: 'p1',
        batchId: 'b2',
        productName: 'Paracetamol 500mg',
        quantity: 1,
        unitPrice: 1000,
      ),
      SaleLine(
        productId: 'p2',
        batchId: 'b3',
        productName: 'Amoxicillin 250mg',
        quantity: 1,
        unitPrice: 1500,
      ),
    ],
  );

  test('itemCount adds up the units on every line', () {
    expect(sale().itemCount, 4);
  });

  test('lineTotal is quantity times unit price', () {
    expect(sale().lines.first.lineTotal, 2000);
  });

  test('sellerName uses the saved name when there is one', () {
    expect(sale(soldByName: 'Eric Mugisha').sellerName, 'Eric Mugisha');
  });

  test('sellerName falls back to soldBy when the name is missing', () {
    expect(sale().sellerName, 'uid-eric');
    expect(sale(soldByName: '  ').sellerName, 'uid-eric');
  });

  test('isCash is true only for cash sales', () {
    expect(sale().isCash, isTrue);
    expect(sale(paymentMethod: 'Mobile Money').isCash, isFalse);
  });
}
