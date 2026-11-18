import '../entities/cart_item.dart';

class ChangeCalculator {
  const ChangeCalculator._();

  static int total(List<CartItem> items) =>
      items.fold(0, (sum, item) => sum + item.lineTotal);

  /// Change owed to the customer, or null if the cash doesn't cover [total].
  static int? change({required int total, required int cashReceived}) {
    if (cashReceived < total) return null;
    return cashReceived - total;
  }
}
