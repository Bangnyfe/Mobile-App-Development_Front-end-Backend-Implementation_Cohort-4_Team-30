import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/domain/services/batch_allocator.dart';

PosBatch batch(String id, String batchNumber, DateTime expiry, int quantity) =>
    PosBatch(
      id: id,
      batchNumber: batchNumber,
      expiryDate: expiry,
      quantity: quantity,
    );

void main() {
  final today = DateTime(2026, 11, 18);

  test('allocates all stock from one sufficient batch', () {
    final b1 = batch('1', 'B001', DateTime(2026, 12, 5), 5);
    final b2 = batch('2', 'B002', DateTime(2027, 1, 10), 10);

    final result = BatchAllocator.allocate(
      batches: [b2, b1],
      quantity: 3,
      today: today,
    );

    expect(result.allocations.single.batchId, '1');
    expect(result.allocations.single.quantity, 3);
  });

  test('splits stock across two batches in FEFO order', () {
    final b1 = batch('1', 'B001', DateTime(2026, 12, 5), 3);
    final b2 = batch('2', 'B002', DateTime(2027, 1, 10), 4);
    final b3 = batch('3', 'B003', DateTime(2027, 3, 15), 10);

    final result = BatchAllocator.allocate(
      batches: [b3, b2, b1],
      quantity: 5,
      today: today,
    );

    expect(
      result.allocations.map((allocation) => allocation.batchId).toList(),
      ['1', '2'],
    );
    expect(
      result.allocations.map((allocation) => allocation.quantity).toList(),
      [3, 2],
    );
  });

  test('splits stock across three batches', () {
    final b1 = batch('1', 'B001', DateTime(2026, 12, 5), 2);
    final b2 = batch('2', 'B002', DateTime(2027, 1, 10), 2);
    final b3 = batch('3', 'B003', DateTime(2027, 3, 15), 10);

    final result = BatchAllocator.allocate(
      batches: [b3, b1, b2],
      quantity: 6,
      today: today,
    );

    expect(
      result.allocations.map((allocation) => allocation.quantity).toList(),
      [2, 2, 2],
    );
  });

  test('uses batch number to break equal expiry ties', () {
    final b003 = batch('3', 'B003', DateTime(2026, 12, 10), 5);
    final b001 = batch('1', 'B001', DateTime(2026, 12, 10), 8);
    final b002 = batch('2', 'B002', DateTime(2026, 12, 10), 3);

    final result = BatchAllocator.allocate(
      batches: [b003, b002, b001],
      quantity: 16,
      today: today,
    );

    expect(
      result.allocations.map((allocation) => allocation.batchNumber).toList(),
      ['B001', 'B002', 'B003'],
    );
  });

  test('rejects insufficient combined stock', () {
    final b1 = batch('1', 'B001', DateTime(2026, 12, 5), 2);
    final b2 = batch('2', 'B002', DateTime(2027, 1, 10), 2);

    expect(
      () =>
          BatchAllocator.allocate(batches: [b1, b2], quantity: 5, today: today),
      throwsA(
        isA<AllocationFailure>()
            .having((error) => error.available, 'available', 4)
            .having((error) => error.requested, 'requested', 5),
      ),
    );
  });

  test('ignores expired and empty batches', () {
    final expired = batch('old', 'B000', DateTime(2026, 11, 17), 10);
    final empty = batch('empty', 'B001', DateTime(2026, 12, 1), 0);
    final valid = batch('valid', 'B002', DateTime(2027, 1, 1), 2);

    final result = BatchAllocator.allocate(
      batches: [expired, empty, valid],
      quantity: 2,
      today: today,
    );

    expect(result.allocations.single.batchId, 'valid');
  });

  test('rejects zero and negative quantities', () {
    final valid = batch('valid', 'B001', DateTime(2027, 1, 1), 5);
    expect(
      () =>
          BatchAllocator.allocate(batches: [valid], quantity: 0, today: today),
      throwsArgumentError,
    );
    expect(
      () =>
          BatchAllocator.allocate(batches: [valid], quantity: -1, today: today),
      throwsArgumentError,
    );
  });
}
