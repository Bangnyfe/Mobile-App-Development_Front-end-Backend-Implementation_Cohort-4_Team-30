import 'package:equatable/equatable.dart';

/// One batch on the shelf that stock can be removed from.
class RemovableBatch extends Equatable {
  const RemovableBatch({
    required this.id,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.costPrice,
  });

  final String id;

  /// Printed on the box, e.g. "MZ2308".
  final String batchNumber;
  final DateTime expiryDate;

  /// Units left in this batch.
  final int quantity;

  /// What the pharmacy paid per unit, in RWF; used for the value written
  /// off.
  final int costPrice;

  /// Expired once the expiry day has passed (the expiry day itself still
  /// counts as in date).
  bool isExpiredOn(DateTime today) {
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.isBefore(DateTime(today.year, today.month, today.day));
  }

  /// Cost value of [units] from this batch, in RWF.
  int costOf(int units) => units * costPrice;

  RemovableBatch copyWith({int? quantity}) => RemovableBatch(
    id: id,
    batchNumber: batchNumber,
    expiryDate: expiryDate,
    quantity: quantity ?? this.quantity,
    costPrice: costPrice,
  );

  @override
  List<Object?> get props => [id, batchNumber, expiryDate, quantity, costPrice];
}

/// A product and its batches, as shown on "Choose batch".
class RemovableProduct extends Equatable {
  const RemovableProduct({
    required this.id,
    required this.name,
    required this.barcode,
    this.details = '',
    this.batches = const [],
  });

  final String id;
  final String name;
  final String barcode;

  /// Form and pack size, e.g. "Tablets · strip of 10".
  final String details;

  /// Sorted by expiry date, earliest first.
  final List<RemovableBatch> batches;

  int get totalUnits =>
      batches.fold(0, (total, batch) => total + batch.quantity);

  /// The batch to offer first: the earliest-expiring one with units left,
  /// so expired stock comes off the shelf before anything else.
  RemovableBatch? get firstBatchWithStock {
    for (final batch in batches) {
      if (batch.quantity > 0) return batch;
    }
    return null;
  }

  RemovableBatch? batchById(String batchId) {
    for (final batch in batches) {
      if (batch.id == batchId) return batch;
    }
    return null;
  }

  /// Search by part of the name (any case) or by barcode digits.
  bool matches(String query) {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return true;
    return name.toLowerCase().contains(text) || barcode.contains(text);
  }

  @override
  List<Object?> get props => [id, name, barcode, details, batches];
}
