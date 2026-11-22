import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/removable_product.dart';
import '../../domain/entities/removal_reason.dart';
import '../../domain/entities/stock_removal.dart';
import '../../domain/removal_rules.dart';
import '../../domain/repositories/stock_removal_repository.dart';

part 'remove_stock_state.dart';

/// Runs the two-step Remove stock flow: choose a batch and quantity, then
/// a reason, then save.
///
/// All rules live here and in [RemovalRules], so the screens only display
/// the state and call these methods.
class RemoveStockCubit extends Cubit<RemoveStockState> {
  RemoveStockCubit(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const RemoveStockState());

  final StockRemovalRepository _repository;
  final DateTime Function() _clock;

  static const loadFailedMessage =
      "Couldn't load your stock. Check your connection and try again.";

  /// Loads the products. From an expiry notification, pass the product,
  /// batch and suggested reason so the flow opens with them selected.
  Future<void> start({
    String? productId,
    String? batchId,
    RemovalReason? suggestedReason,
  }) async {
    emit(const RemoveStockState());
    final List<RemovableProduct> products;
    try {
      products = await _repository.loadProducts();
    } catch (_) {
      emit(
        const RemoveStockState(
          status: RemoveStockStatus.loadFailure,
          message: loadFailedMessage,
        ),
      );
      return;
    }

    emit(RemoveStockState(status: RemoveStockStatus.ready, products: products));
    if (productId != null) selectProduct(productId);
    if (batchId != null) selectBatch(batchId);
    if (suggestedReason != null) {
      emit(
        state.copyWith(
          reason: () => suggestedReason,
          suggestedReason: () => suggestedReason,
        ),
      );
    }
    // From a notification the batch is already known, so the flow opens
    // on the Reason step (Figma: "Remove stock - from notification").
    if (batchId != null && state.canContinue) {
      emit(
        state.copyWith(step: RemoveStockStep.reason, fromNotification: true),
      );
    }
  }

  void search(String query) => emit(state.copyWith(query: query));

  /// "Change": back to the product list.
  void clearProduct() => emit(
    state.copyWith(
      productId: () => null,
      batchId: () => null,
      quantity: 0,
      suggestedReason: () => null,
    ),
  );

  /// Continue from Choose batch to Reason, once a batch and quantity are
  /// valid.
  void goToReason() {
    if (state.canContinue) emit(state.copyWith(step: RemoveStockStep.reason));
  }

  /// Back from Reason to Choose batch, keeping the selection.
  void backToBatch() {
    if (state.step == RemoveStockStep.reason) {
      emit(state.copyWith(step: RemoveStockStep.chooseBatch));
    }
  }

  /// Picks a product and offers its earliest-expiring batch with stock.
  void selectProduct(String productId) {
    final product = _productById(productId);
    if (product == null) return;
    emit(
      state.copyWith(
        productId: () => productId,
        batchId: () => null,
        quantity: 0,
      ),
    );
    final first = product.firstBatchWithStock;
    if (first != null) selectBatch(first.id);
  }

  /// An expired batch starts with all its units and Expired suggested,
  /// since it should come off the shelf entirely; others start at 1.
  void selectBatch(String batchId) {
    final batch = state.product?.batchById(batchId);
    if (batch == null) return;
    final expired = batch.isExpiredOn(_clock());
    emit(
      state.copyWith(
        batchId: () => batchId,
        quantity: expired ? batch.quantity : (batch.quantity > 0 ? 1 : 0),
        suggestedReason: () => expired ? RemovalReason.expired : null,
      ),
    );
  }

  /// Keeps the quantity between 1 and the units in the batch.
  void setQuantity(int quantity) {
    final batch = state.batch;
    if (batch == null || batch.quantity <= 0) return;
    emit(state.copyWith(quantity: quantity.clamp(1, batch.quantity)));
  }

  void increment() => setQuantity(state.quantity + 1);

  void decrement() => setQuantity(state.quantity - 1);

  void removeAll() {
    final batch = state.batch;
    if (batch != null) setQuantity(batch.quantity);
  }

  void selectReason(RemovalReason reason) =>
      emit(state.copyWith(reason: () => reason));

  void setNote(String note) => emit(state.copyWith(note: note));

  /// Saves the removal. On success the stock is reloaded, so every screen
  /// that reads it afterwards shows the lower quantity.
  Future<void> submit() async {
    final batch = state.batch;
    final reason = state.reason;
    if (!state.canSubmit || batch == null || reason == null) return;

    emit(
      state.copyWith(
        submitStatus: SubmitStatus.submitting,
        message: () => null,
      ),
    );
    try {
      final removal = await _repository.removeStock(
        StockRemovalRequest(
          productId: state.productId!,
          batchId: batch.id,
          quantity: state.quantity,
          reason: reason,
          note: state.note.trim(),
        ),
      );
      final products = await _repository.loadProducts();
      emit(
        state.copyWith(
          products: products,
          submitStatus: SubmitStatus.success,
          step: RemoveStockStep.done,
          result: () => removal,
        ),
      );
    } on StockRemovalFailure catch (failure) {
      emit(
        state.copyWith(
          submitStatus: SubmitStatus.failure,
          message: () => failure.message,
        ),
      );
    }
  }

  RemovableProduct? _productById(String productId) {
    for (final product in state.products) {
      if (product.id == productId) return product;
    }
    return null;
  }
}
