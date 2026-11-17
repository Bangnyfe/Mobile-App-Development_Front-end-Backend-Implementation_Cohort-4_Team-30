import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('amount adds thousands separators', () {
      expect(Formatters.amount(0), '0');
      expect(Formatters.amount(900), '900');
      expect(Formatters.amount(284500), '284,500');
      expect(Formatters.amount(1250000), '1,250,000');
    });

    test('rwf prefixes the currency', () {
      expect(Formatters.rwf(6900), 'RWF 6,900');
    });

    test('dayHeader matches the prototype format', () {
      expect(Formatters.dayHeader(DateTime(2026, 9, 25)), 'Friday, 25 Sep');
    });

    test('time uses 24-hour clock', () {
      expect(Formatters.time(DateTime(2026, 9, 25, 9, 5)), '09:05');
      expect(Formatters.time(DateTime(2026, 9, 25, 14, 32)), '14:32');
    });

    test('percentChange rounds and adds a sign for increases', () {
      expect(Formatters.percentChange(12.04), '+12%');
      expect(Formatters.percentChange(-3.6), '-4%');
      expect(Formatters.percentChange(0.2), '0%');
    });

    test('itemCount uses singular for one item', () {
      expect(Formatters.itemCount(1), '1 item');
      expect(Formatters.itemCount(3), '3 items');
    });
  });
}
