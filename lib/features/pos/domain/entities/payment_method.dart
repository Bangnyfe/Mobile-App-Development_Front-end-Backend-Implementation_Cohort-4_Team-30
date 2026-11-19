/// Payment method labels stored on a sale.
///
/// The app doesn't process payments. The method is only recorded on the
/// receipt, and only cash sales need cash received and change.
abstract final class PaymentMethods {
  static const cash = 'Cash';
  static const mobileMoney = 'Mobile Money';
  static const card = 'Card';

  static const all = [cash, mobileMoney, card];
}
