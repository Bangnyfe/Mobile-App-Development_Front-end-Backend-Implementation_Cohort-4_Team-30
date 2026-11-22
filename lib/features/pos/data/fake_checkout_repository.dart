import '../domain/repositories/checkout_repository.dart';

/// Records sales in memory, until scanned products come from Firestore.
///
/// `FirestoreCheckoutRepository` deducts stock from the batch documents the
/// cart names. The Sell tab still finds products with
/// `FakeProductLookupRepository`, whose batches don't exist in Firestore, so
/// a real checkout would always fail with "batch no longer available".
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
