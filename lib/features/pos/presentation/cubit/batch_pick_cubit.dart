import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cart_item.dart';
import '../../domain/entities/pos_batch.dart';
import '../../domain/services/fefo_picker.dart';

part 'batch_pick_state.dart';

/// The batch and quantity chosen on Product found, before they go into the
/// cart. Starts on the FEFO batch (earliest expiry) with 1 unit.
class BatchPickCubit extends Cubit<BatchPickState> {
  /// [cart] is the cart when the screen opened, so units of a batch that
  /// are already in it can't be added twice.
  BatchPickCubit({
    required List<PosBatch> batches,
    required DateTime today,
    List<CartItem> cart = const [],
  }) : super(_initial(batches, today, cart));

  static BatchPickState _initial(
    List<PosBatch> batches,
    DateTime today,
    List<CartItem> cart,
  ) {
    final sellable = FefoPicker.sortedSellable(batches, today: today);
    final inCart = <String, int>{};
    for (final item in cart) {
      for (final allocation in item.allocations) {
        inCart.update(
          allocation.batchId,
          (units) => units + allocation.quantity,
          ifAbsent: () => allocation.quantity,
        );
      }
    }
    return BatchPickState(
      sellable: sellable,
      selected: FefoPicker.pick(batches, today: today),
      quantity: 1,
      inCart: inCart,
    );
  }

  /// Picks another batch, keeping the quantity within its stock.
  void select(String batchId) {
    final batch = state.sellable.where((b) => b.id == batchId).firstOrNull;
    if (batch == null) return;
    final next = state.copyWith(selected: batch);
    final quantity = next.quantity.clamp(1, next.max < 1 ? 1 : next.max);
    emit(next.copyWith(quantity: quantity));
  }

  void increment() {
    if (state.quantity < state.max) {
      emit(state.copyWith(quantity: state.quantity + 1));
    }
  }

  void decrement() {
    if (state.quantity > 1) emit(state.copyWith(quantity: state.quantity - 1));
  }
}
