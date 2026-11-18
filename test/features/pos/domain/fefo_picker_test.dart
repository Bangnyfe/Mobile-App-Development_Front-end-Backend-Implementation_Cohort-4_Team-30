import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/domain/services/fefo_picker.dart';

PosBatch batch(String id, DateTime expiry, int qty) =>
    PosBatch(id: id, batchNumber: 'B-$id', expiryDate: expiry, quantity: qty);

void main() {
  final today = DateTime(2026, 11, 18);

  group('FefoPicker.pick', () {
    test('picks the earliest expiry', () {
      final late = batch('late', DateTime(2027, 6, 1), 10);
      final soon = batch('soon', DateTime(2026, 12, 1), 10);
      expect(FefoPicker.pick([late, soon], today: today), soon);
    });

    test('skips expired batches', () {
      final expired = batch('old', DateTime(2026, 10, 1), 10);
      final valid = batch('ok', DateTime(2027, 1, 1), 10);
      expect(FefoPicker.pick([expired, valid], today: today), valid);
    });

    test('skips batches with zero quantity', () {
      final empty = batch('empty', DateTime(2026, 12, 1), 0);
      final stocked = batch('stocked', DateTime(2027, 1, 1), 5);
      expect(FefoPicker.pick([empty, stocked], today: today), stocked);
    });

    test('a batch expiring today is still sellable', () {
      final todayBatch = batch('today', DateTime(2026, 11, 18), 3);
      expect(FefoPicker.pick([todayBatch], today: today), todayBatch);
    });

    test('returns null when nothing is sellable', () {
      final expired = batch('old', DateTime(2026, 10, 1), 10);
      final empty = batch('empty', DateTime(2027, 1, 1), 0);
      expect(FefoPicker.pick([expired, empty], today: today), isNull);
    });

    test('returns null for an empty list', () {
      expect(FefoPicker.pick(const [], today: today), isNull);
    });

    test('on equal expiry the first in the list wins', () {
      final a = batch('a', DateTime(2026, 12, 1), 5);
      final b = batch('b', DateTime(2026, 12, 1), 5);
      expect(FefoPicker.pick([a, b], today: today), a);
    });

    test('uses batch number before document id on equal expiry', () {
      final b003Input = batch('z', DateTime(2026, 12, 10), 5);
      final b001 = PosBatch(
        id: 'a',
        batchNumber: 'B001',
        expiryDate: DateTime(2026, 12, 10),
        quantity: 8,
      );
      final b003 = PosBatch(
        id: b003Input.id,
        batchNumber: 'B003',
        expiryDate: b003Input.expiryDate,
        quantity: b003Input.quantity,
      );
      final b002 = PosBatch(
        id: 'b',
        batchNumber: 'B002',
        expiryDate: DateTime(2026, 12, 10),
        quantity: 3,
      );
      expect(
        FefoPicker.pick([b003, b001, b002], today: today)?.batchNumber,
        'B001',
      );
    });

    test('ignores hours, minutes and seconds on expiry date', () {
      final earlyMorning = PosBatch(
        id: 'morning',
        batchNumber: 'B001',
        expiryDate: DateTime(2026, 12, 1, 0, 0, 1),
        quantity: 5,
      );
      final later = PosBatch(
        id: 'later',
        batchNumber: 'B002',
        expiryDate: DateTime(2026, 12, 1, 23, 59, 59),
        quantity: 5,
      );
      expect(
        FefoPicker.pick([later, earlyMorning], today: today),
        earlyMorning,
      );
    });
  });
}
