import 'package:equatable/equatable.dart';

import 'removal_reason.dart';

/// What the user asked to remove (the input to the removal).
class StockRemovalRequest extends Equatable {
  const StockRemovalRequest({
    required this.productId,
    required this.batchId,
    required this.quantity,
    required this.reason,
    this.note = '',
  });

  final String productId;
  final String batchId;
  final int quantity;
  final RemovalReason reason;
  final String note;

  @override
  List<Object?> get props => [productId, batchId, quantity, reason, note];
}

/// A recorded removal: one document in `stockRemovals`, with the product
/// and batch names filled in for display.
class StockRemoval extends Equatable {
  const StockRemoval({
    required this.id,
    required this.productId,
    required this.productName,
    required this.batchId,
    required this.batchNumber,
    required this.quantity,
    required this.reason,
    required this.costValue,
    required this.removedBy,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final String productId;
  final String productName;
  final String batchId;
  final String batchNumber;
  final int quantity;
  final RemovalReason reason;
  final String note;

  /// quantity × the batch's cost price, in RWF: the value written off.
  final int costValue;

  /// Name of the person who removed it.
  final String removedBy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    batchId,
    batchNumber,
    quantity,
    reason,
    note,
    costValue,
    removedBy,
    createdAt,
  ];
}
