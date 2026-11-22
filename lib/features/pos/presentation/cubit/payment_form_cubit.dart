import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payment_method.dart';
import '../../domain/services/change_calculator.dart';

part 'payment_form_state.dart';

/// The payment method and cash received typed on Checkout, before
/// `CheckoutCubit` confirms the sale.
class PaymentFormCubit extends Cubit<PaymentFormState> {
  PaymentFormCubit() : super(const PaymentFormState());

  void selectMethod(String method) {
    if (!PaymentMethods.all.contains(method)) return;
    emit(PaymentFormState(method: method, cashReceived: state.cashReceived));
  }

  /// [text] as typed; anything but digits is ignored. Empty clears it.
  void setCashReceived(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    emit(
      PaymentFormState(
        method: state.method,
        cashReceived: int.tryParse(digits),
      ),
    );
  }
}
