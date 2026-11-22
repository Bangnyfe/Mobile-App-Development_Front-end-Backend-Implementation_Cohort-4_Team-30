import '../domain/entities/sale.dart';
import '../domain/repositories/sales_repository.dart';

/// The sales of whichever pharmacy the signed-in user belongs to.
///
/// The app's repositories are created once, before anyone signs in, but
/// each pharmacy's sales live in their own collection. This looks up the
/// current pharmacy on every call and hands the work to the repository for
/// it (in the app, a `FirestoreSalesRepository`), so a new sign-in never
/// sees the previous user's sales.
class CurrentPharmacySalesRepository implements SalesRepository {
  /// [pharmacyId] returns the signed-in user's pharmacy ID, and
  /// [forPharmacy] creates the repository for one pharmacy.
  CurrentPharmacySalesRepository({
    required this._pharmacyId,
    required this._forPharmacy,
  });

  final String? Function() _pharmacyId;
  final SalesRepository Function(String pharmacyId) _forPharmacy;

  String? _cachedId;
  SalesRepository? _cached;

  /// The repository for the current pharmacy, or null when the user has no
  /// pharmacy (signed out, or not set up yet).
  SalesRepository? get _current {
    final id = _pharmacyId();
    if (id == null) return null;
    if (id != _cachedId) {
      _cachedId = id;
      _cached = _forPharmacy(id);
    }
    return _cached;
  }

  @override
  Stream<List<Sale>> watchSales({int limit = SalesRepository.defaultLimit}) =>
      _current?.watchSales(limit: limit) ?? Stream.value(const []);

  @override
  Future<Sale?> getSale(String saleId) async => _current?.getSale(saleId);
}
