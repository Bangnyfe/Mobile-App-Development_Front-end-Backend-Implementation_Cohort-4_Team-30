import 'package:equatable/equatable.dart';

/// A checkout allocation for one batch within a product cart line.
class BatchAllocation extends Equatable {
  const BatchAllocation({
    required this.batchId,
    required this.batchNumber,
    required this.quantity,
  });

  final String batchId;
  final String batchNumber;
  final int quantity;

  @override
  List<Object?> get props => [batchId, batchNumber, quantity];
}
