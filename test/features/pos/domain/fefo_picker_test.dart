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
  });
}
