import '../../../core/domain/user_role.dart';
import '../domain/entities/pharmacy_account.dart';
import '../domain/repositories/account_repository.dart';

/// The prototype's sample pharmacy, for widget tests. The app uses
/// `FirestoreAccountRepository`.
class FakeAccountRepository implements AccountRepository {
  const FakeAccountRepository();

  static const _owner = StaffMember(
    id: 'u1',
    name: 'Aline Uwase',
    email: 'aline@amanipharmacy.rw',
    role: UserRole.owner,
  );

  @override
  Future<PharmacyAccount> load() async => const PharmacyAccount(
    pharmacy: Pharmacy(
      id: 'ph1',
      name: 'Amani Pharmacy',
      district: 'Nyarugenge',
      city: 'Kigali',
      phone: '+250 788 000 000',
      address: 'KN 4 Ave',
    ),
    user: _owner,
    staff: [
      _owner,
      StaffMember(
        id: 'u2',
        name: 'Eric Mugisha',
        email: 'eric@amanipharmacy.rw',
        role: UserRole.pharmacist,
      ),
      StaffMember(
        id: 'u3',
        name: 'Diane Ingabire',
        email: 'diane@amanipharmacy.rw',
        role: UserRole.pharmacist,
      ),
    ],
    categories: [
      ProductCategory(id: 'c1', name: 'Analgesics', productCount: 38),
      ProductCategory(id: 'c2', name: 'Antibiotics', productCount: 52),
      ProductCategory(id: 'c3', name: 'Antimalarials', productCount: 21),
      ProductCategory(id: 'c4', name: 'Antihypertensives', productCount: 27),
      ProductCategory(id: 'c5', name: 'Antidiabetics', productCount: 18),
      ProductCategory(id: 'c6', name: 'Antihistamines', productCount: 15),
      ProductCategory(id: 'c7', name: 'Antacids', productCount: 12),
      ProductCategory(
        id: 'c8',
        name: 'Vitamins & supplements',
        productCount: 44,
      ),
      ProductCategory(id: 'c9', name: 'Cough & cold', productCount: 31),
      ProductCategory(id: 'c10', name: 'Skin care', productCount: 29),
      ProductCategory(id: 'c11', name: 'Eye & ear care', productCount: 14),
      ProductCategory(id: 'c12', name: 'First aid', productCount: 36),
      ProductCategory(id: 'c13', name: 'Oral rehydration', productCount: 9),
      ProductCategory(id: 'c14', name: 'Baby care', productCount: 22),
    ],
  );

  /// Does nothing: the Settings screens show the saved details from
  /// `AccountCubit`, and tests check saving through their own repository.
  @override
  Future<void> updatePharmacy(Pharmacy pharmacy) async {}

  /// Does nothing: tests check Log out through their own repository.
  @override
  Future<void> signOut() async {}
}
