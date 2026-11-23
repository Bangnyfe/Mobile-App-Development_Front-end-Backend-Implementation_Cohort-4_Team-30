part of 'payment_form_cubit.dart';

class PaymentFormState extends Equatable {
  const PaymentFormState({
    this.method = PaymentMethods.cash,
    this.cashReceived,
  });

  /// One of [PaymentMethods.all].
  final String method;

  /// Whole RWF, or null while the field is empty.
  final int? cashReceived;

  bool get isCash => method == PaymentMethods.cash;

  /// Change to give back on a cash sale of [total], or null while the cash
  /// doesn't cover it. Other methods are paid in full, so always 0.
  int? changeFor(int total) {
    if (!isCash) return 0;
    final cash = cashReceived;
    if (cash == null) return null;
    return ChangeCalculator.change(total: total, cashReceived: cash);
  }

  /// Whether the payment covers [total], so the sale can be confirmed.
  bool covers(int total) => changeFor(total) != null;

  @override
  List<Object?> get props => [method, cashReceived];
}
