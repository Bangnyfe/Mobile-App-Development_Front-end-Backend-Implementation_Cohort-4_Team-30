import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removable_product.dart';

void main() {
  final expired = RemovableBatch(
    id: 'b1',
    batchNumber: 'MZ2308',
    expiryDate: DateTime(2026, 10, 27),
    quantity: 14,
    costPrice: 1100,
  );
  final inDate = RemovableBatch(
    id: 'b2',
    batchNumber: 'MZ2410',
    expiryDate: DateTime(2028, 4, 1),
    quantity: 9,
    costPrice: 1100,
  );
  final product = RemovableProduct(
    id: 'p1',
    name: 'Metronidazole 400mg',
    barcode: '6001007012345',
    batches: [expired, inDate],
  );

  test('a batch is expired only after its expiry day', () {
    expect(expired.isExpiredOn(DateTime(2026, 10, 27, 18)), isFalse);
    expect(expired.isExpiredOn(DateTime(2026, 10, 28)), isTrue);
  });

  test('cost written off is units times cost price', () {
    expect(expired.costOf(14), 15400);
  });

  test('totals units and offers the earliest batch with stock first', () {
    expect(product.totalUnits, 23);
    expect(product.firstBatchWithStock, expired);

    final emptied = RemovableProduct(
      id: 'p1',
      name: 'Metronidazole 400mg',
      barcode: '6001007012345',
      batches: [expired.copyWith(quantity: 0), inDate],
    );
    expect(emptied.firstBatchWithStock, inDate);
  });

  test('search matches part of the name in any case, or the barcode', () {
    expect(product.matches('metro'), isTrue);
    expect(product.matches('METRONIDAZOLE'), isTrue);
    expect(product.matches('600100701'), isTrue);
    expect(product.matches('amox'), isFalse);
    expect(product.matches('  '), isTrue);
  });
}
