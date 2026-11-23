import '../entities/pharmacy_account.dart';

/// The signed-in user's pharmacy, staff and categories, and signing out.
abstract interface class AccountRepository {
  Future<PharmacyAccount> load();

  /// Saves [pharmacy]'s name, district, city, phone and address (owner
  /// only). A null phone or address removes it.
  Future<void> updatePharmacy(Pharmacy pharmacy);

  Future<void> signOut();
}
