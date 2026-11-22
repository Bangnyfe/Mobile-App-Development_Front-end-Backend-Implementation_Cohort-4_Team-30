import 'package:equatable/equatable.dart';

import 'firestore_fields.dart';

/// A received lot of one product, stored at
/// `pharmacies/{pharmacyId}/products/{productId}/batches/{batchId}`.
///
/// Every batch also stores its [pharmacyId] and [productId], so a
/// collection-group query over all `batches` (e.g. expiry alerts) can filter
/// by pharmacy and still tell which product each batch belongs to.
class Batch extends Equatable {
  const Batch({
    required this.id,
    required this.pharmacyId,
    required this.productId,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.costPrice,
    required this.receivedBy,
    this.receivedByName = '',
    this.receivedAt,
  });

  /// `batchId`, the document ID.
  final String id;
  final String pharmacyId;

  /// The parent product.
  final String productId;

  /// Printed on the pack.
  final String batchNumber;
  final DateTime expiryDate;

  /// Units in stock.
  final int quantity;

  /// Whole RWF per unit paid to the supplier.
  final int costPrice;

  /// UID of the person who received it, and their name at the time.
  final String receivedBy;
  final String receivedByName;

  /// Null until the server timestamp is written.
  final DateTime? receivedAt;

  /// Whole RWF the units in stock cost.
  int get stockValue => quantity * costPrice;

  /// Expired once its expiry day is before [today] (date only), matching
  /// `PosBatch.isExpiredOn`.
  bool isExpiredOn(DateTime today) {
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final day = DateTime(today.year, today.month, today.day);
    return expiry.isBefore(day);
  }

  /// Returns null when the document has no expiry date, so a batch that
  /// can't be dated is never shown as sellable stock.
  static Batch? fromMap(String id, Map<String, dynamic> map) {
    final expiryDate = readDate(map['expiryDate']);
    if (expiryDate == null) return null;
    return Batch(
      id: id,
      pharmacyId: readString(map['pharmacyId']),
      productId: readString(map['productId']),
      batchNumber: readString(map['batchNumber']),
      expiryDate: expiryDate,
      quantity: readInt(map['quantity']),
      costPrice: readInt(map['costPrice']),
      receivedBy: readString(map['receivedBy']),
      receivedByName: readString(map['receivedByName']),
      receivedAt: readDate(map['receivedAt']),
    );
  }

  /// The stored fields. The ID is the document ID, so it isn't repeated.
  Map<String, Object?> toMap() => {
    'batchNumber': batchNumber,
    'expiryDate': writeDate(expiryDate),
    'quantity': quantity,
    'costPrice': costPrice,
    'receivedAt': writeDate(receivedAt),
    'receivedBy': receivedBy,
    'receivedByName': receivedByName,
    'pharmacyId': pharmacyId,
    'productId': productId,
  };

  Batch copyWith({
    String? id,
    String? pharmacyId,
    String? productId,
    String? batchNumber,
    DateTime? expiryDate,
    int? quantity,
    int? costPrice,
    String? receivedBy,
    String? receivedByName,
    DateTime? receivedAt,
  }) => Batch(
    id: id ?? this.id,
    pharmacyId: pharmacyId ?? this.pharmacyId,
    productId: productId ?? this.productId,
    batchNumber: batchNumber ?? this.batchNumber,
    expiryDate: expiryDate ?? this.expiryDate,
    quantity: quantity ?? this.quantity,
    costPrice: costPrice ?? this.costPrice,
    receivedBy: receivedBy ?? this.receivedBy,
    receivedByName: receivedByName ?? this.receivedByName,
    receivedAt: receivedAt ?? this.receivedAt,
  );

  @override
  List<Object?> get props => [
    id,
    pharmacyId,
    productId,
    batchNumber,
    expiryDate,
    quantity,
    costPrice,
    receivedBy,
    receivedByName,
    receivedAt,
  ];
}
