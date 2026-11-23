import 'package:equatable/equatable.dart';

import 'firestore_fields.dart';

/// A product category, stored at
/// `pharmacies/{pharmacyId}/categories/{categoryId}`.
///
/// Named `ProductCategory` because Flutter's `material.dart` already
/// exports a `Category` annotation.
class ProductCategory extends Equatable {
  const ProductCategory({required this.id, required this.name, this.createdAt});

  /// `categoryId`, the document ID.
  final String id;
  final String name;

  /// Null until the server timestamp is written.
  final DateTime? createdAt;

  factory ProductCategory.fromMap(String id, Map<String, dynamic> map) =>
      ProductCategory(
        id: id,
        name: readString(map['name'], fallback: 'Unnamed category'),
        createdAt: readDate(map['createdAt']),
      );

  /// The stored fields. The ID is the document ID, so it isn't repeated.
  Map<String, Object?> toMap() => {
    'name': name,
    'createdAt': writeDate(createdAt),
  };

  ProductCategory copyWith({String? name, DateTime? createdAt}) =>
      ProductCategory(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, name, createdAt];
}
