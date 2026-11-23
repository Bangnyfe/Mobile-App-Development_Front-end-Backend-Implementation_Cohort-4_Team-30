import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/inventory_failure.dart';
import '../../domain/repositories/inventory_repository.dart';

part 'product_details_state.dart';

/// One product and its batches, live, with the owner's edits.
///
/// The edit and delete methods return null when saved, or the message to
/// show when not, so the page can close a dialog or show a snack bar.
class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit(this._repository, this.productId)
    : super(const ProductDetailsState());

  final InventoryRepository _repository;
  final String productId;
  StreamSubscription<InventoryItem?>? _subscription;

  /// True while this phone deletes the product, so its own delete isn't
  /// shown as "no longer exists" while the page closes.
  bool _deleting = false;

  Future<void> start() async {
    // Not awaited: the old stream may already have ended with an error, and
    // the new listener doesn't depend on it.
    unawaited(_subscription?.cancel());
    emit(const ProductDetailsState());
    _subscription = _repository.watchItem(productId).listen(
      (item) {
        if (item == null && _deleting) return;
        emit(
          item == null
              ? const ProductDetailsState(status: ProductDetailsStatus.notFound)
              : state.copyWith(status: ProductDetailsStatus.loaded, item: item),
        );
      },
      onError: (Object error) => emit(
        state.copyWith(
          status: ProductDetailsStatus.failure,
          errorMessage: _messageFor(error),
        ),
      ),
    );
  }

  /// A null [reorderLevel] goes back to the pharmacy default.
  Future<String?> updatePricing({
    required int sellingPrice,
    int? reorderLevel,
  }) => _save(
    () => _repository.updatePricing(
      productId,
      sellingPrice: sellingPrice,
      reorderLevel: reorderLevel,
    ),
  );

  Future<String?> deleteProduct() async {
    _deleting = true;
    final message = await _save(() => _repository.deleteProduct(productId));
    _deleting = message == null;
    return message;
  }

  Future<String?> deleteBatch(String batchId) => _save(
    () => _repository.deleteBatch(productId: productId, batchId: batchId),
  );

  Future<String?> _save(Future<void> Function() action) async {
    emit(state.copyWith(saving: true));
    try {
      await action();
      return null;
    } catch (error) {
      return _messageFor(error);
    } finally {
      if (!isClosed) emit(state.copyWith(saving: false));
    }
  }

  static String _messageFor(Object error) =>
      error is InventoryFailure ? error.message : InventoryFailure.generic;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
