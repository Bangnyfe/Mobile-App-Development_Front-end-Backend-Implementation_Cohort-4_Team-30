import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../../domain/services/change_calculator.dart';
import 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(this._repository) : super(const CheckoutState.initial());

  final CheckoutRepository _repository;

  Future<void> checkout({
    required List<CartItem> items,
    required String pharmacyId,
    required String saleId,
    required String receiptNo,
    required String soldBy,
    required String paymentMethod,
    required int cashReceived,
  }) async {
    if (items.isEmpty) {
      emit(const CheckoutState.failure('The cart is empty.'));
      return;
    }

    final total = ChangeCalculator.total(items);
    final change = ChangeCalculator.change(
      total: total,
      cashReceived: cashReceived,
    );
    if (change == null) {
      emit(const CheckoutState.failure('Insufficient cash received.'));
      return;
    }

    emit(const CheckoutState.processing());
    try {
      await _repository.checkout(
        CheckoutRequest(
          pharmacyId: pharmacyId,
          saleId: saleId,
          receiptNo: receiptNo,
          soldBy: soldBy,
          paymentMethod: paymentMethod,
          cashReceived: cashReceived,
          change: change,
          items: items,
        ),
      );
      emit(CheckoutState.success(receiptNo));
    } catch (error) {
      final message = error is CheckoutException
          ? error.message
          : 'Checkout failed. Please try again.';
      emit(CheckoutState.failure(message));
    }
  }
}
