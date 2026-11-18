import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/domain/entities/cart_item.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/domain/entities/pos_product.dart';
import 'package:team30_app/features/pos/domain/services/change_calculator.dart';

CartItem item(int price, int qty) => CartItem(
  product: PosProduct(
    id: 'p$price',
    barcode: '123',
    name: 'Item',
    sellingPrice: price,
  ),
  batch: PosBatch(
    id: 'b1',
    batchNumber: 'B-1',
    expiryDate: DateTime(2027, 1, 1),
    quantity: 100,
  ),
  quantity: qty,
);

void main() {
  group('ChangeCalculator.total', () {
    test('empty cart is zero', () {
      expect(ChangeCalculator.total(const []), 0);
    });

    test('single line is price times quantity', () {
      expect(ChangeCalculator.total([item(500, 3)]), 1500);
    });

    test('sums several lines', () {
      expect(ChangeCalculator.total([item(500, 2), item(1200, 1)]), 2200);
    });
  });

  group('ChangeCalculator.change', () {
    test('exact cash gives zero change', () {
      expect(ChangeCalculator.change(total: 2200, cashReceived: 2200), 0);
    });

    test('overpayment returns the difference', () {
      expect(ChangeCalculator.change(total: 2200, cashReceived: 5000), 2800);
    });

    test('underpayment returns null', () {
      expect(ChangeCalculator.change(total: 2200, cashReceived: 2000), isNull);
    });
  });
}
