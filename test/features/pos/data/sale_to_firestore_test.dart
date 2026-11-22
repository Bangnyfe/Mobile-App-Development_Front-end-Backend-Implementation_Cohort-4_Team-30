import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/data/firestore_checkout_repository.dart';
import 'package:team30_app/features/pos/domain/entities/batch_allocation.dart';
import 'package:team30_app/features/pos/domain/entities/cart_item.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/domain/entities/pos_product.dart';
import 'package:team30_app/features/pos/domain/repositories/checkout_repository.dart';

void main() {
  const product = PosProduct(
    id: 'p1',
    barcode: '6001007012342',
    name: 'Metronidazole 400mg',
    sellingPrice: 1500,
  );
  final batch = PosBatch(
    id: 'b1',
    batchNumber: 'MZ2410',
    expiryDate: DateTime(2028, 4, 1),
    quantity: 9,
  );

  CheckoutRequest request(List<BatchAllocation> allocations) => CheckoutRequest(
    pharmacyId: 'ph1',
    saleId: 'sale-1',
    receiptNo: '261122-101500',
    soldBy: 'u2',
    soldByName: 'Eric',
    paymentMethod: 'Cash',
    cashReceived: 5000,
    change: 500,
    items: [
      CartItem(
        product: product,
        batch: batch,
        quantity: 3,
        allocations: allocations,
      ),
    ],
  );

  test('saves the sale with the ERD fields, including who sold it', () {
    final sale = saleToFirestore(
      request(const [
        BatchAllocation(batchId: 'b1', batchNumber: 'MZ2410', quantity: 3),
      ]),
    );

    expect(sale['receiptNo'], '261122-101500');
    expect(sale['soldBy'], 'u2');
    expect(sale['soldByName'], 'Eric');
    expect(sale['paymentMethod'], 'Cash');
    expect(sale['total'], 4500);
    expect(sale['cashReceived'], 5000);
    expect(sale['change'], 500);
    expect(sale['createdAt'], isA<FieldValue>());
    expect(sale['items'], [
      {
        'productId': 'p1',
        'batchId': 'b1',
        'productName': 'Metronidazole 400mg',
        'quantity': 3,
        'unitPrice': 1500,
      },
    ]);
  });

  test('a line taken from two batches becomes one item per batch', () {
    final sale = saleToFirestore(
      request(const [
        BatchAllocation(batchId: 'b1', batchNumber: 'MZ2410', quantity: 2),
        BatchAllocation(batchId: 'b2', batchNumber: 'MZ2501', quantity: 1),
      ]),
    );

    final items = sale['items']! as List<Map<String, Object>>;
    expect(items.map((item) => (item['batchId'], item['quantity'])), [
      ('b1', 2),
      ('b2', 1),
    ]);
  });

  test('a line without a batch allocation is refused', () {
    expect(
      () => saleToFirestore(request(const [])),
      throwsA(isA<CheckoutException>()),
    );
  });
}
