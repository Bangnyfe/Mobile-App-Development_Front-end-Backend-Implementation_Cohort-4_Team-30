import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/presentation/cubit/batch_pick_cubit.dart';
import 'package:team30_app/features/pos/presentation/cubit/cart_cubit.dart';

import 'pos_page_test_helpers.dart';

void main() {
  /// Expires after [amoxBatch] (14 Oct 2026), so FEFO never suggests it.
  final later = PosBatch(
    id: 'b-ax2503',
    batchNumber: 'AX2503',
    expiryDate: DateTime(2028, 3, 3),
    quantity: 60,
  );
  final expired = PosBatch(
    id: 'b-old',
    batchNumber: 'OLD1',
    expiryDate: DateTime(2026, 9, 1),
    quantity: 30,
  );
  final empty = PosBatch(
    id: 'b-empty',
    batchNumber: 'EMPTY1',
    expiryDate: DateTime(2026, 9, 30),
    quantity: 0,
  );

  BatchPickCubit build({List<PosBatch>? batches, CartCubit? cart}) =>
      BatchPickCubit(
        batches: batches ?? [later, amoxBatch, expired, empty],
        today: today,
        cart: cart?.state.items ?? const [],
      );

  group('starts', () {
    test('on the earliest-expiry sellable batch with 1 unit', () {
      final state = build().state;

      expect(state.selected, amoxBatch);
      expect(state.suggested, amoxBatch);
      expect(state.quantity, 1);
      expect(state.max, 18);
      expect(state.canAdd, isTrue);
      expect(state.stockAfter, 17);
    });

    test('listing only sellable batches, earliest expiry first', () {
      expect(build().state.sellable, [amoxBatch, later]);
    });

    test('with nothing to sell when every batch is expired or empty', () {
      final state = build(batches: [expired, empty]).state;

      expect(state.sellable, isEmpty);
      expect(state.selected, isNull);
      expect(state.max, 0);
      expect(state.canAdd, isFalse);
    });

    test('counting units of each batch already in the cart', () {
      final cart = CartCubit(clock: () => today)
        ..addItem(product: amoxicillin, batches: [amoxBatch], quantity: 5);
      addTearDown(cart.close);

      final state = build(cart: cart).state;

      expect(state.reserved, 5);
      expect(state.max, 13);
      expect(state.stockAfter, 12);
    });

    test('unable to add when the whole batch is already in the cart', () {
      final cart = CartCubit(clock: () => today)
        ..addItem(product: amoxicillin, batches: [amoxBatch], quantity: 18);
      addTearDown(cart.close);

      final state = build(cart: cart).state;

      expect(state.max, 0);
      expect(state.canAdd, isFalse);
    });
  });

  blocTest<BatchPickCubit, BatchPickState>(
    'increment stops at the units left in the batch',
    build: () => build(batches: [amoxBatch.copyWith(quantity: 2)]),
    act: (cubit) => cubit
      ..increment()
      ..increment()
      ..increment(),
    expect: () => [
      isA<BatchPickState>().having((s) => s.quantity, 'quantity', 2),
    ],
  );

  blocTest<BatchPickCubit, BatchPickState>(
    'decrement never goes below 1',
    build: build,
    act: (cubit) => cubit
      ..increment()
      ..decrement()
      ..decrement(),
    expect: () => [
      isA<BatchPickState>().having((s) => s.quantity, 'quantity', 2),
      isA<BatchPickState>().having((s) => s.quantity, 'quantity', 1),
    ],
  );

  blocTest<BatchPickCubit, BatchPickState>(
    'choosing another batch keeps the quantity when it fits',
    build: build,
    act: (cubit) => cubit
      ..increment()
      ..select(later.id),
    skip: 1,
    expect: () => [
      isA<BatchPickState>()
          .having((s) => s.selected, 'selected', later)
          .having((s) => s.quantity, 'quantity', 2)
          .having((s) => s.stockAfter, 'stockAfter', 58),
    ],
  );

  blocTest<BatchPickCubit, BatchPickState>(
    'choosing a smaller batch lowers the quantity to what it holds',
    build: () => build(batches: [later, amoxBatch.copyWith(quantity: 3)]),
    act: (cubit) {
      cubit.select(later.id);
      for (var i = 0; i < 9; i++) {
        cubit.increment();
      }
      cubit.select(amoxBatch.id);
    },
    verify: (cubit) {
      expect(cubit.state.selected?.id, amoxBatch.id);
      expect(cubit.state.quantity, 3);
    },
  );

  blocTest<BatchPickCubit, BatchPickState>(
    'ignores a batch that is not sellable',
    build: build,
    act: (cubit) => cubit
      ..select(expired.id)
      ..select('no-such-batch'),
    expect: () => <BatchPickState>[],
  );
}
