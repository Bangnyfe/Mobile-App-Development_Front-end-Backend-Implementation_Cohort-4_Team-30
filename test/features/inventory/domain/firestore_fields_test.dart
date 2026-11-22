import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/inventory/domain/entities/firestore_fields.dart';

void main() {
  group('readString', () {
    test('returns a string as it is', () {
      expect(readString('Amoxicillin'), 'Amoxicillin');
    });

    test('falls back for a missing or wrongly typed value', () {
      expect(readString(null), '');
      expect(readString(42), '');
      expect(readString(null, fallback: 'Unnamed'), 'Unnamed');
    });
  });

  group('readInt', () {
    test('rounds a stray double down', () {
      expect(readInt(1500), 1500);
      expect(readInt(1500.9), 1500);
    });

    test('falls back for a missing or wrongly typed value', () {
      expect(readInt(null), 0);
      expect(readInt('12'), 0);
      expect(readInt(null, fallback: 7), 7);
    });
  });

  group('readNullableInt', () {
    test('keeps null as null, so "use the default" survives', () {
      expect(readNullableInt(null), isNull);
      expect(readNullableInt('20'), isNull);
      expect(readNullableInt(20), 20);
      expect(readNullableInt(20.0), 20);
    });
  });

  group('dates', () {
    final date = DateTime(2027, 3, 31);

    test('reads a Timestamp or a DateTime', () {
      expect(readDate(Timestamp.fromDate(date)), date);
      expect(readDate(date), date);
    });

    test('reads null while a server timestamp is pending', () {
      expect(readDate(null), isNull);
      expect(readDate('2027-03-31'), isNull);
    });

    test('writes a Timestamp, or null', () {
      expect(writeDate(date), Timestamp.fromDate(date));
      expect(writeDate(null), isNull);
    });
  });
}
