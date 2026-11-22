import 'package:equatable/equatable.dart';

import 'firestore_fields.dart';

/// A product the pharmacy stocks, stored at
/// `pharmacies/{pharmacyId}/products/{productId}`.
///
/// Stock itself lives in the product's `batches`; a product only knows its
/// price and when to reorder.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.sellingPrice,
    this.form = '',
    this.packSize = '',
    this.categoryId,
    this.reorderLevel,
    this.createdAt,
    this.updatedAt,
  });

  /// `productId`, the document ID.
  final String id;

  /// GTIN printed on the pack, unique within a pharmacy.
  final String barcode;
  final String name;

  /// Tablet, syrup, ...
  final String form;

  /// e.g. "10 × 10".
  final String packSize;

  /// The product's category, or null when it has none.
  final String? categoryId;

  /// Whole RWF per unit.
  final int sellingPrice;

  /// The product's own reorder level, or null to use the pharmacy default
  /// (`pharmacies/{id}.defaultReorderLevel`).
  final int? reorderLevel;

  /// Null until the server timestamps are written.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// The reorder level that applies: the product's own, or [pharmacyDefault].
  int effectiveReorderLevel(int pharmacyDefault) =>
      reorderLevel ?? pharmacyDefault;

  /// Low on stock when [totalUnits] across all batches is at or below the
  /// reorder level that applies.
  bool isLowStock(int totalUnits, {required int pharmacyDefault}) =>
      totalUnits <= effectiveReorderLevel(pharmacyDefault);

  factory Product.fromMap(String id, Map<String, dynamic> map) => Product(
    id: id,
    barcode: readString(map['barcode']),
    name: readString(map['name'], fallback: 'Unnamed product'),
    form: readString(map['form']),
    packSize: readString(map['packSize']),
    categoryId: map['categoryId'] as String?,
    sellingPrice: readInt(map['sellingPrice']),
    reorderLevel: readNullableInt(map['reorderLevel']),
    createdAt: readDate(map['createdAt']),
    updatedAt: readDate(map['updatedAt']),
  );

  /// The stored fields. The ID is the document ID, so it isn't repeated.
  /// `reorderLevel` is written as null on purpose: null means "use the
  /// pharmacy default".
  Map<String, Object?> toMap() => {
    'barcode': barcode,
    'name': name,
    'form': form,
    'packSize': packSize,
    'categoryId': categoryId,
    'sellingPrice': sellingPrice,
    'reorderLevel': reorderLevel,
    'createdAt': writeDate(createdAt),
    'updatedAt': writeDate(updatedAt),
  };

  /// [clearCategory] and [clearReorderLevel] set those fields back to null,
  /// which `copyWith(categoryId: null)` can't express.
  Product copyWith({
    String? id,
    String? barcode,
    String? name,
    String? form,
    String? packSize,
    String? categoryId,
    bool clearCategory = false,
    int? sellingPrice,
    int? reorderLevel,
    bool clearReorderLevel = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Product(
    id: id ?? this.id,
    barcode: barcode ?? this.barcode,
    name: name ?? this.name,
    form: form ?? this.form,
    packSize: packSize ?? this.packSize,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    reorderLevel: clearReorderLevel ? null : reorderLevel ?? this.reorderLevel,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    barcode,
    name,
    form,
    packSize,
    categoryId,
    sellingPrice,
    reorderLevel,
    createdAt,
    updatedAt,
  ];
}
