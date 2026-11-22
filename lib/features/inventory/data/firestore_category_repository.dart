import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/category.dart';
import '../domain/repositories/category_repository.dart';
import 'inventory_firestore_guard.dart';

/// Categories in `pharmacies/{pharmacyId}/categories`.
class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository({
    required this.pharmacyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String pharmacyId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories => _firestore
      .collection('pharmacies')
      .doc(pharmacyId)
      .collection('categories');

  @override
  Stream<List<ProductCategory>> watchCategories() => _categories
      .orderBy('name')
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            ProductCategory.fromMap(doc.id, doc.data()),
        ],
      )
      .withInventoryFailures();

  @override
  Future<ProductCategory> addCategory(String name) => guardInventory(() async {
    final ref = _categories.doc();
    final trimmed = name.trim();
    await ref.set({'name': trimmed, 'createdAt': FieldValue.serverTimestamp()});
    return ProductCategory(id: ref.id, name: trimmed);
  });

  @override
  Future<void> renameCategory(String categoryId, String name) =>
      guardInventory(
        () => _categories.doc(categoryId).update({'name': name.trim()}),
      );

  @override
  Future<void> deleteCategory(String categoryId) =>
      guardInventory(() => _categories.doc(categoryId).delete());
}
