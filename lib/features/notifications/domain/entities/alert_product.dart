import 'package:equatable/equatable.dart';

/// A product and its batches: what the alerts are worked out from.
///
/// Alerts are calculated on the device from products and batches, so there
/// is no notifications collection in Firestore to keep in sync.
class AlertProduct extends Equatable {
  const AlertProduct({
    required this.id,
    required this.name,
    this.reorderLevel,
    this.batches = const [],
  });

  final String id;
  final String name;

  /// The product's own reorder level, or null to use the low-stock
  /// threshold from Settings.
  final int? reorderLevel;

  final List<AlertBatch> batches;

  @override
  List<Object?> get props => [id, name, reorderLevel, batches];
}

class AlertBatch extends Equatable {
  const AlertBatch({
    required this.id,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
  });

  final String id;
  final String batchNumber;
  final DateTime expiryDate;

  /// Units left on the shelf.
  final int quantity;

  @override
  List<Object?> get props => [id, batchNumber, expiryDate, quantity];
}
