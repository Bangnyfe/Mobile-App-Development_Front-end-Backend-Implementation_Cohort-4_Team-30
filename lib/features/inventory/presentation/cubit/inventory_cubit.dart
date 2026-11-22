import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/inventory_failure.dart';
import '../../domain/inventory_filter.dart';
import '../../domain/repositories/inventory_repository.dart';

part 'inventory_state.dart';

/// Keeps the Inventory list live: every change to a product or batch, on
/// any phone, shows straight away.
class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit(
    this._repository, {
    InventoryFilter initialFilter = InventoryFilter.all,
  }) : super(InventoryState(filter: initialFilter));

  final InventoryRepository _repository;
  StreamSubscription<List<InventoryItem>>? _subscription;

  /// Starts (or restarts, after an error) listening to the inventory.
  Future<void> start() async {
    // Not awaited: the old stream may already have ended with an error, and
    // the new listener doesn't depend on it.
    unawaited(_subscription?.cancel());
    emit(state.copyWith(status: InventoryStatus.loading));
    _subscription = _repository.watchInventory().listen(
      (items) =>
          emit(state.copyWith(status: InventoryStatus.loaded, items: items)),
      onError: (Object error) => emit(
        state.copyWith(
          status: InventoryStatus.failure,
          errorMessage: error is InventoryFailure
              ? error.message
              : InventoryFailure.generic,
        ),
      ),
    );
  }

  void selectFilter(InventoryFilter filter) =>
      emit(state.copyWith(filter: filter, errorMessage: state.errorMessage));

  void search(String query) =>
      emit(state.copyWith(query: query, errorMessage: state.errorMessage));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
