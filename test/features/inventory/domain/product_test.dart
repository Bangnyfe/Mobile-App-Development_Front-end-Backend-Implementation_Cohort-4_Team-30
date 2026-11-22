import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/inventory/domain/entities/product.dart';

void main() {
  final created = DateTime(2026, 11, 1, 9);
  final updated = DateTime(2026, 11, 20, 14, 30);

  final product = Product(
    id: 'p1',
    barcode: '6001007023454',
    name: 'Amoxicillin 500mg',
    form: 'Capsules',
    packSize: 'Box of 21',
    categoryId: 'antibiotics',
    sellingPrice: 4500,
    reorderLevel: 30,
    createdAt: created,
    updatedAt: updated,
  );

  group('Product.fromMap', () {
    test('reads every field', () {
      final read = Product.fromMap('p1', {
        'barcode': '6001007023454',
        'name': 'Amoxicillin 500mg',
        'form': 'Capsules',
        'packSize': 'Box of 21',
        'categoryId': 'antibiotics',
        'sellingPrice': 4500,
        'reorderLevel': 30,
        'createdAt': Timestamp.fromDate(created),
        'updatedAt': Timestamp.fromDate(updated),
      });

      expect(read, product);
    });

    test('survives a document typed by hand with fields missing', () {
      final read = Product.fromMap('p2', {'sellingPrice': 700.0});

      expect(read.id, 'p2');
      expect(read.name, 'Unnamed product');
      expect(read.barcode, '');
      expect(read.form, '');
      expect(read.sellingPrice, 700);
      expect(read.categoryId, isNull);
      expect(read.reorderLevel, isNull);
      expect(read.createdAt, isNull);
    });
  });

  group('Product.toMap', () {
    test('round-trips through fromMap', () {
      expect(Product.fromMap('p1', product.toMap()), product);
    });

    test('leaves the ID out, since it is the document ID', () {
      expect(product.toMap().containsKey('id'), isFalse);
    });

    test('writes a null reorder level, meaning "use the default"', () {
      final map = product.copyWith(clearReorderLevel: true).toMap();

      expect(map.containsKey('reorderLevel'), isTrue);
      expect(map['reorderLevel'], isNull);
    });

    test('stores money as a whole number', () {
      expect(product.toMap()['sellingPrice'], isA<int>());
    });
  });

  group('reorder level', () {
    test('uses the product level when it has one', () {
      expect(product.effectiveReorderLevel(20), 30);
    });

    test('falls back to the pharmacy default', () {
      final noLevel = product.copyWith(clearReorderLevel: true);
      expect(noLevel.effectiveReorderLevel(20), 20);
    });

    test('is low on stock at or below the level', () {
      expect(product.isLowStock(31, pharmacyDefault: 20), isFalse);
      expect(product.isLowStock(30, pharmacyDefault: 20), isTrue);
      expect(product.isLowStock(0, pharmacyDefault: 20), isTrue);
    });
  });

  group('copyWith', () {
    test('changes only what is passed', () {
      final changed = product.copyWith(sellingPrice: 5000);

      expect(changed.sellingPrice, 5000);
      expect(changed.copyWith(sellingPrice: 4500), product);
    });

    test('can clear the category', () {
      expect(product.copyWith(clearCategory: true).categoryId, isNull);
    });
  });
}
