import '../domain/repositories/checkout_repository.dart';

/// Records sales in memory, for widget tests. The app uses
/// `FirestoreCheckoutRepository`, which takes the stock from the batch
/// documents the cart names.
class FakeCheckoutRepository implements CheckoutRepository {
  FakeCheckoutRepository();

  final _sales = <String, CheckoutRequest>{};

  /// When set, every checkout throws a [CheckoutException] with this message.
  String? failWith;

  /// Sales recorded so far, by sale ID.
  Map<String, CheckoutRequest> get sales => Map.unmodifiable(_sales);

  @override
  Future<void> checkout(CheckoutRequest request) async {
    final message = failWith;
    if (message != null) throw CheckoutException(message);
    for (final item in request.items) {
      if (item.allocations.isEmpty) {
        throw const CheckoutException(
          'Checkout failed because the cart allocation is missing.',
        );
      }
    }
    // Same sale ID twice is the same sale, as in Firestore.
    _sales.putIfAbsent(request.saleId, () => request);
  }
}
