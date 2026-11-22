/// A failed inventory action, with a message that can be shown as it is.
class InventoryFailure implements Exception {
  const InventoryFailure(this.message);

  final String message;

  static const duplicateBarcode =
      'A product with this barcode is already registered.';
  static const notFound =
      'This item no longer exists. It may have been deleted on another '
      'phone.';
  static const ownerOnly = 'Only the pharmacy owner can do this.';
  static const generic =
      'Something went wrong. Check your connection and try again.';

  @override
  String toString() => 'InventoryFailure: $message';
}
