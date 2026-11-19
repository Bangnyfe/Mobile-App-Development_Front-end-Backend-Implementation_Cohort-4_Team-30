import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/domain/entities/pos_product.dart';
import 'package:team30_app/features/pos/presentation/cubit/cart_cubit.dart';
import 'package:team30_app/features/pos/presentation/cubit/cart_state.dart';

void main() {
  final product = PosProduct(
    id: 'p1',
    barcode: '123',
    name: 'Product',
    sellingPrice: 500,
  );
  final today = DateTime(2026, 11, 18);
  final b1 = PosBatch(
    id: 'b1',
    batchNumber: 'B001',
    expiryDate: DateTime(2026, 12, 5),
    quantity: 3,
  );
  final b2 = PosBatch(
    id: 'b2',
    batchNumber: 'B002',
    expiryDate: DateTime(2027, 1, 10),
    quantity: 4,
  );

  blocTest<CartCubit, CartState>(
    'rejects zero quantity',
    build: () => CartCubit(clock: () => today),
    act: (cubit) =>
        cubit.addItem(product: product, batches: [b1, b2], quantity: 0),
    expect: () => [
      isA<CartState>().having(
        (state) => state.error,
        'error',
        'Quantity must be greater than zero.',
      ),
    ],
  );

  blocTest<CartCubit, CartState>(
    'rejects negative quantity',
    build: () => CartCubit(clock: () => today),
    act: (cubit) =>
        cubit.addItem(product: product, batches: [b1, b2], quantity: -2),
    expect: () => [
      isA<CartState>().having(
        (state) => state.error,
        'error',
        'Quantity must be greater than zero.',
      ),
    ],
  );

  blocTest<CartCubit, CartState>(
    'splits quantity and recalculates on update',
    build: () => CartCubit(clock: () => today),
    act: (cubit) {
      cubit.addItem(product: product, batches: [b2, b1], quantity: 5);
      cubit.updateQuantity(product.id, 6);
    },
    verify: (cubit) {
      expect(cubit.state.items.single.quantity, 6);
      expect(
        cubit.state.items.single.allocations.map((a) => a.quantity).toList(),
        [3, 3],
      );
    },
  );

  blocTest<CartCubit, CartState>(
    'prevents reducing below one',
    build: () => CartCubit(clock: () => today),
    act: (cubit) {
      cubit.addItem(product: product, batches: [b1, b2], quantity: 2);
      cubit.updateQuantity(product.id, 0);
    },
    verify: (cubit) {
      expect(cubit.state.items.single.quantity, 2);
      expect(cubit.state.error, 'Quantity must be greater than zero.');
    },
  );

  blocTest<CartCubit, CartState>(
    'rejects quantity above combined stock',
    build: () => CartCubit(clock: () => today),
    act: (cubit) =>
        cubit.addItem(product: product, batches: [b1, b2], quantity: 8),
    expect: () => [
      isA<CartState>().having(
        (state) => state.error,
        'error',
        'Insufficient stock. Available: 7, Requested: 8.',
      ),
    ],
  );

  blocTest<CartCubit, CartState>(
    'emits the same error again when it happens twice in a row',
    build: () => CartCubit(clock: () => today),
    act: (cubit) {
      cubit.addItem(product: product, batches: [b1, b2], quantity: 8);
      cubit.addItem(product: product, batches: [b1, b2], quantity: 8);
    },
    expect: () => [
      isA<CartState>()
          .having((state) => state.error, 'error', startsWith('Insufficient'))
          .having((state) => state.errorCount, 'errorCount', 1),
      isA<CartState>()
          .having((state) => state.error, 'error', startsWith('Insufficient'))
          .having((state) => state.errorCount, 'errorCount', 2),
    ],
  );
}
