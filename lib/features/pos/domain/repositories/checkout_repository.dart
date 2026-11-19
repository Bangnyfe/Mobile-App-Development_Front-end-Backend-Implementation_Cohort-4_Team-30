import '../entities/cart_item.dart';

class CheckoutException implements Exception {
  const CheckoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CheckoutRequest {
  const CheckoutRequest({
    required this.pharmacyId,
    required this.saleId,
    required this.receiptNo,
    required this.soldBy,
    required this.paymentMethod,
    required this.cashReceived,
    required this.change,
    required this.items,
  });

  final String pharmacyId;
  final String saleId;
  final String receiptNo;
  final String soldBy;
  final String paymentMethod;
  final int cashReceived;
  final int change;
  final List<CartItem> items;

  int get total => items.fold<int>(0, (sum, item) => sum + item.lineTotal);
}

abstract interface class CheckoutRepository {
  Future<void> checkout(CheckoutRequest request);
}
