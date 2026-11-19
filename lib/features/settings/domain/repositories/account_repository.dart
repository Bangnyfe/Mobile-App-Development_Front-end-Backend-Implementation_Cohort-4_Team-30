import '../entities/pharmacy_account.dart';

/// The signed-in user's pharmacy, staff and categories, and signing out.
abstract interface class AccountRepository {
  Future<PharmacyAccount> load();

  Future<void> signOut();
}
