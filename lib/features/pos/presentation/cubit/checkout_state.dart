import 'package:equatable/equatable.dart';

class CheckoutState extends Equatable {
  const CheckoutState.initial()
    : status = CheckoutStatus.initial,
      error = null,
      receiptNo = null;

  const CheckoutState.processing()
    : status = CheckoutStatus.processing,
      error = null,
      receiptNo = null;

  const CheckoutState.success(this.receiptNo)
    : status = CheckoutStatus.success,
      error = null;

  const CheckoutState.failure(this.error)
    : status = CheckoutStatus.failure,
      receiptNo = null;

  final CheckoutStatus status;
  final String? error;
  final String? receiptNo;

  @override
  List<Object?> get props => [status, error, receiptNo];
}

enum CheckoutStatus { initial, processing, success, failure }
