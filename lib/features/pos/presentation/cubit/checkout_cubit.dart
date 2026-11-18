import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cart_item.dart';
import '../../domain/entities/payment_method.dart';
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
    int? cashReceived,
  }) async {
    if (items.isEmpty) {
      emit(const CheckoutState.failure('The cart is empty.'));
      return;
    }

    final total = ChangeCalculator.total(items);

    // Only cash sales take cash and give change. Mobile Money and Card are
    // just labels on the receipt, so they're recorded as paid in full.
    final isCash = paymentMethod == PaymentMethods.cash;
    final paid = isCash ? cashReceived : total;
    final change = paid == null
        ? null
        : ChangeCalculator.change(total: total, cashReceived: paid);
    if (paid == null || change == null) {
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
          cashReceived: paid,
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
