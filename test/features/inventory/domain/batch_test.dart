import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/inventory/domain/entities/batch.dart';

void main() {
  final expiry = DateTime(2027, 6, 30);
  final received = DateTime(2026, 11, 22, 10, 15);

  final batch = Batch(
    id: 'b1',
    pharmacyId: 'ph1',
    productId: 'p1',
    batchNumber: 'AMX-2411',
    expiryDate: expiry,
    quantity: 120,
    costPrice: 3000,
    receivedBy: 'u1',
    receivedByName: 'Aline Uwase',
    receivedAt: received,
  );

  group('Batch.fromMap', () {
    test('reads every field', () {
      final read = Batch.fromMap('b1', {
        'pharmacyId': 'ph1',
        'productId': 'p1',
        'batchNumber': 'AMX-2411',
        'expiryDate': Timestamp.fromDate(expiry),
        'quantity': 120,
        'costPrice': 3000,
        'receivedBy': 'u1',
        'receivedByName': 'Aline Uwase',
        'receivedAt': Timestamp.fromDate(received),
      });

      expect(read, batch);
    });

    test('returns null without an expiry date, so it is never sold', () {
      expect(Batch.fromMap('b2', {'quantity': 10}), isNull);
    });

    test('defaults missing numbers to zero', () {
      final read = Batch.fromMap('b3', {
        'expiryDate': Timestamp.fromDate(expiry),
      })!;

      expect(read.quantity, 0);
      expect(read.costPrice, 0);
      expect(read.receivedAt, isNull);
    });
  });

  group('Batch.toMap', () {
    test('round-trips through fromMap', () {
      expect(Batch.fromMap('b1', batch.toMap()), batch);
    });

    test('keeps pharmacyId and productId for the collection-group query', () {
      final map = batch.toMap();

      expect(map['pharmacyId'], 'ph1');
      expect(map['productId'], 'p1');
      expect(map.containsKey('id'), isFalse);
    });
  });

  test('stockValue is units times cost', () {
    expect(batch.stockValue, 360000);
  });

  group('isExpiredOn', () {
    test('is not expired on its expiry day', () {
      expect(batch.isExpiredOn(DateTime(2027, 6, 30, 23, 59)), isFalse);
    });

    test('is expired from the next day', () {
      expect(batch.isExpiredOn(DateTime(2027, 7, 1)), isTrue);
    });
  });

  test('copyWith changes only what is passed', () {
    final lowered = batch.copyWith(quantity: 100);

    expect(lowered.quantity, 100);
    expect(lowered.copyWith(quantity: 120), batch);
  });
}
