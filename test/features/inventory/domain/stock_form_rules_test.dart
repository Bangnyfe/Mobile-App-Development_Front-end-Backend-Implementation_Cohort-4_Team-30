import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/inventory/domain/stock_form_rules.dart';

void main() {
  group('barcode', () {
    test('is required', () {
      expect(StockFormRules.barcode(''), isNotNull);
    });

    test('needs a valid check digit', () {
      expect(StockFormRules.barcode('6001007023454'), isNull);
      expect(StockFormRules.barcode('6001007023455'), isNotNull);
      expect(StockFormRules.barcode('12345'), isNotNull);
    });

    test('is stored as the scanner reads it', () {
      expect(
        StockFormRules.normalizedBarcode(' 6001007023454 '),
        '6001007023454',
      );
      expect(StockFormRules.normalizedBarcode('abc'), isNull);
    });
  });

  group('batchNumber', () {
    test('is required and short', () {
      expect(StockFormRules.batchNumber(' '), isNotNull);
      expect(StockFormRules.batchNumber('X' * 31), isNotNull);
      expect(StockFormRules.batchNumber('AMX-2411'), isNull);
    });
  });

  group('quantity', () {
    test('needs at least one unit', () {
      expect(StockFormRules.quantity(''), isNotNull);
      expect(StockFormRules.quantity('0'), isNotNull);
      expect(StockFormRules.quantity('100001'), isNotNull);
      expect(StockFormRules.quantity('50'), isNull);
    });
  });

  group('costPrice', () {
    test('is whole RWF and may be zero (free samples)', () {
      expect(StockFormRules.costPrice(''), isNotNull);
      expect(StockFormRules.costPrice('1.5'), isNotNull);
      expect(StockFormRules.costPrice('0'), isNull);
      expect(StockFormRules.costPrice('3000'), isNull);
    });
  });

  group('expiryDate', () {
    final today = DateTime(2026, 11, 22, 18);

    test('is required', () {
      expect(StockFormRules.expiryDate(null, today: today), isNotNull);
    });

    test('rejects an expired batch', () {
      expect(
        StockFormRules.expiryDate(DateTime(2026, 11, 21), today: today),
        isNotNull,
      );
    });

    test('accepts today and later', () {
      expect(
        StockFormRules.expiryDate(DateTime(2026, 11, 22), today: today),
        isNull,
      );
      expect(
        StockFormRules.expiryDate(DateTime(2028, 6, 30), today: today),
        isNull,
      );
    });
  });
}
