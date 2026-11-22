import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/inventory_failure.dart';
import '../../domain/repositories/inventory_repository.dart';

part 'register_product_state.dart';

/// Registers a new product, offering the pharmacy's categories.
class RegisterProductCubit extends Cubit<RegisterProductState> {
  RegisterProductCubit(this._repository) : super(const RegisterProductState());

  final InventoryRepository _repository;
  StreamSubscription<List<ProductCategory>>? _subscription;

  /// Listens to the categories. Without them the form still works; the
  /// product just has no category.
  void start() {
    _subscription ??= _repository.watchCategories().listen(
      (categories) => emit(state.copyWith(categories: categories)),
      onError: (Object _) {},
    );
  }

  /// Returns the new category, or null (with [RegisterProductState.errorMessage]
  /// set) if it couldn't be saved.
  Future<ProductCategory?> addCategory(String name) async {
    try {
      return await _repository.addCategory(name);
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)));
      return null;
    }
  }

  Future<void> save(Product product) async {
    if (state.saving) return;
    emit(state.copyWith(saving: true));
    try {
      final saved = await _repository.registerProduct(product);
      emit(state.copyWith(saving: false, saved: saved));
    } catch (error) {
      emit(state.copyWith(saving: false, errorMessage: _messageFor(error)));
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
