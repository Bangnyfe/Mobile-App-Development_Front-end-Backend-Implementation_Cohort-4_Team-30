import '../../settings/domain/entities/pharmacy_account.dart';
import '../../settings/domain/repositories/account_repository.dart';
import '../domain/repositories/auth_repository.dart';

/// The Settings tab's [AccountRepository], with Log out done by Firebase
/// auth.
///
/// Signing out makes AuthBloc report "signed out", and the router then
/// shows Login. The pharmacy, staff and categories still come from
/// [details] until a Firestore account repository replaces it; this class
/// can then be removed.
class AuthBackedAccountRepository implements AccountRepository {
  const AuthBackedAccountRepository({
    required this._details,
    required this._auth,
  });

  final AccountRepository _details;
  final AuthRepository _auth;

  @override
  Future<PharmacyAccount> load() => _details.load();

  @override
  Future<void> signOut() => _auth.signOut();
}
