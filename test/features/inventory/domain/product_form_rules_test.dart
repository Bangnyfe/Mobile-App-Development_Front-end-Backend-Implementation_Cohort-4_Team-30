import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/inventory/domain/product_form_rules.dart';

void main() {
  group('name', () {
    test('is required', () {
      expect(ProductFormRules.name(null), isNotNull);
      expect(ProductFormRules.name('   '), isNotNull);
    });

    test('accepts a normal name', () {
      expect(ProductFormRules.name('Amoxicillin 500mg'), isNull);
    });

    test('rejects a very long name', () {
      expect(ProductFormRules.name('x' * 81), isNotNull);
    });
  });

  group('sellingPrice', () {
    test('is required and whole', () {
      expect(ProductFormRules.sellingPrice(''), isNotNull);
      expect(ProductFormRules.sellingPrice('12.5'), isNotNull);
      expect(ProductFormRules.sellingPrice('1,500'), isNotNull);
    });

    test('must be above zero and not absurd', () {
      expect(ProductFormRules.sellingPrice('0'), isNotNull);
      expect(ProductFormRules.sellingPrice('10000001'), isNotNull);
    });

    test('accepts whole RWF', () {
      expect(ProductFormRules.sellingPrice(' 4500 '), isNull);
    });
  });

  group('reorderLevel', () {
    test('may be left empty for the default', () {
      expect(ProductFormRules.reorderLevel(''), isNull);
      expect(ProductFormRules.parseReorderLevel(''), isNull);
    });

    test('accepts a whole number, including zero', () {
      expect(ProductFormRules.reorderLevel('0'), isNull);
      expect(ProductFormRules.reorderLevel('30'), isNull);
      expect(ProductFormRules.parseReorderLevel(' 30 '), 30);
    });

    test('rejects anything else', () {
      expect(ProductFormRules.reorderLevel('ten'), isNotNull);
      expect(ProductFormRules.reorderLevel('-1'), isNotNull);
      expect(ProductFormRules.reorderLevel('100001'), isNotNull);
    });
  });
}
