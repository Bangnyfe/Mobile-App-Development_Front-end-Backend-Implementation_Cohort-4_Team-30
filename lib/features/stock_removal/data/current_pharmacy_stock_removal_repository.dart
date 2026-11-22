import '../domain/entities/removable_product.dart';
import '../domain/entities/stock_removal.dart';
import '../domain/repositories/stock_removal_repository.dart';

/// The stock of whichever pharmacy the signed-in user belongs to.
///
/// Like `CurrentPharmacySalesRepository`: the app's repositories are made
/// once, before anyone signs in, so this looks up the pharmacy on every
/// call and hands the work to the repository for it (in the app, a
/// `FirestoreStockRemovalRepository`).
class CurrentPharmacyStockRemovalRepository implements StockRemovalRepository {
  /// [pharmacyId] returns the signed-in user's pharmacy ID, and
  /// [forPharmacy] creates the repository for one pharmacy.
  CurrentPharmacyStockRemovalRepository({
    required this._pharmacyId,
    required this._forPharmacy,
  });

  final String? Function() _pharmacyId;
  final StockRemovalRepository Function(String pharmacyId) _forPharmacy;

  String? _cachedId;
  StockRemovalRepository? _cached;

  static const noPharmacyMessage =
      'Your session has ended. Please sign in again.';

  /// The repository for the current pharmacy, or null when the user has no
  /// pharmacy (signed out, or not set up yet).
  StockRemovalRepository? get _current {
    final id = _pharmacyId();
    if (id == null) return null;
    if (id != _cachedId) {
      _cachedId = id;
      _cached = _forPharmacy(id);
    }
    return _cached;
  }

  @override
  Future<List<RemovableProduct>> loadProducts() async =>
      await _current?.loadProducts() ?? const [];

  @override
  Future<List<StockRemoval>> loadRemovals({required DateTime since}) async =>
      await _current?.loadRemovals(since: since) ?? const [];

  @override
  Future<StockRemoval> removeStock(StockRemovalRequest request) {
    final current = _current;
    if (current == null) {
      return Future.error(const StockRemovalFailure(noPharmacyMessage));
    }
    return current.removeStock(request);
  }
}
