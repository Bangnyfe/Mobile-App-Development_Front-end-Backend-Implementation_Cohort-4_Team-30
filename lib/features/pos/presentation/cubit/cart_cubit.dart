import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cart_item.dart';
import '../../domain/entities/pos_batch.dart';
import '../../domain/entities/pos_product.dart';
import '../../domain/services/batch_allocator.dart';
import '../../domain/services/fefo_picker.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const CartState.initial());

  final DateTime Function() _clock;

  void addItem({
    required PosProduct product,
    required List<PosBatch> batches,
    required int quantity,
  }) {
    if (quantity <= 0) {
      emit(state.withError('Quantity must be greater than zero.'));
      return;
    }

    try {
      final allocation = BatchAllocator.allocate(
        batches: batches,
        quantity: quantity,
        today: _clock(),
      );
      final index = state.items.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (index >= 0) {
        final existing = state.items[index];
        final combinedQuantity = existing.quantity + quantity;
        final reallocated = BatchAllocator.allocate(
          batches: batches,
          quantity: combinedQuantity,
          today: _clock(),
        );
        final firstBatch = FefoPicker.sortedSellable(
          batches,
          today: _clock(),
        ).first;
        final updated = existing.copyWith(
          quantity: combinedQuantity,
          batch: firstBatch,
          availableBatches: batches,
          allocations: reallocated.allocations,
        );
        final items = List<CartItem>.from(state.items);
        items[index] = updated;
        emit(CartState(items: items));
      } else {
        final firstBatch = FefoPicker.sortedSellable(
          batches,
          today: _clock(),
        ).first;
        final items = List<CartItem>.from(state.items)
          ..add(
            CartItem(
              product: product,
              batch: firstBatch,
              quantity: quantity,
              availableBatches: batches,
              allocations: allocation.allocations,
            ),
          );
        emit(CartState(items: items));
      }
    } on AllocationFailure catch (error) {
      emit(state.withError(error.message));
    } on ArgumentError catch (error) {
      emit(state.withError(error.message.toString()));
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      emit(state.withError('Quantity must be greater than zero.'));
      return;
    }

    final index = state.items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index < 0) return;

    final item = state.items[index];
    try {
      final allocation = BatchAllocator.allocate(
        batches: item.availableBatches,
        quantity: quantity,
        today: _clock(),
      );
      final firstBatch = FefoPicker.sortedSellable(
        item.availableBatches,
        today: _clock(),
      ).first;
      final items = List<CartItem>.from(state.items);
      items[index] = item.copyWith(
        quantity: quantity,
        batch: firstBatch,
        allocations: allocation.allocations,
      );
      emit(CartState(items: items));
    } on AllocationFailure catch (error) {
      emit(state.withError(error.message));
    }
  }

  void removeItem(String productId) {
    emit(
      CartState(
        items: state.items
            .where((item) => item.product.id != productId)
            .toList(),
      ),
    );
  }

  void clear() => emit(const CartState.initial());
}
