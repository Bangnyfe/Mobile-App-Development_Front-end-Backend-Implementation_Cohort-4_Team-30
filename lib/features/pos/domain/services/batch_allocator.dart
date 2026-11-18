import '../entities/batch_allocation.dart';
import '../entities/pos_batch.dart';
import 'fefo_picker.dart';

class AllocationFailure implements Exception {
  const AllocationFailure(this.available, this.requested);

  final int available;
  final int requested;

  String get message =>
      'Insufficient stock. Available: $available, Requested: $requested.';

  @override
  String toString() => message;
}

class AllocationResult {
  const AllocationResult({required this.allocations, required this.available});

  final List<BatchAllocation> allocations;
  final int available;
}

class BatchAllocator {
  const BatchAllocator._();

  static AllocationResult allocate({
    required List<PosBatch> batches,
    required int quantity,
    required DateTime today,
  }) {
    if (quantity <= 0) {
      throw ArgumentError('Cart quantity must be greater than zero.');
    }

    final sorted = FefoPicker.sortedSellable(batches, today: today);
    final available = sorted.fold<int>(
      0,
      (total, batch) => total + batch.quantity,
    );
    if (available < quantity) {
      throw AllocationFailure(available, quantity);
    }

    var remaining = quantity;
    final allocations = <BatchAllocation>[];
    for (final batch in sorted) {
      if (remaining == 0) break;
      final allocated = remaining < batch.quantity ? remaining : batch.quantity;
      if (allocated > 0) {
        allocations.add(
          BatchAllocation(
            batchId: batch.id,
            batchNumber: batch.batchNumber,
            quantity: allocated,
          ),
        );
        remaining -= allocated;
      }
    }

    return AllocationResult(allocations: allocations, available: available);
  }
}
