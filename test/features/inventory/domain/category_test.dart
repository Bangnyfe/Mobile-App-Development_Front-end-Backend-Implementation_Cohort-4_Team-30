import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/inventory/domain/entities/category.dart';

void main() {
  final created = DateTime(2026, 11, 2);
  final category = ProductCategory(
    id: 'c1',
    name: 'Antibiotics',
    createdAt: created,
  );

  test('fromMap reads every field', () {
    final read = ProductCategory.fromMap('c1', {
      'name': 'Antibiotics',
      'createdAt': Timestamp.fromDate(created),
    });

    expect(read, category);
  });

  test('fromMap names a category with no name', () {
    expect(ProductCategory.fromMap('c2', {}).name, 'Unnamed category');
  });

  test('toMap round-trips through fromMap', () {
    expect(ProductCategory.fromMap('c1', category.toMap()), category);
  });

  test('copyWith keeps the ID', () {
    final renamed = category.copyWith(name: 'Antibiotics & antifungals');

    expect(renamed.id, 'c1');
    expect(renamed.name, 'Antibiotics & antifungals');
  });
}
