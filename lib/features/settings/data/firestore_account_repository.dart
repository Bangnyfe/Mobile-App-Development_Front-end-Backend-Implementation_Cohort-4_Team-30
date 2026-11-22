import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/entities/app_user.dart';
import '../domain/entities/pharmacy_account.dart';
import '../domain/repositories/account_repository.dart';
import 'account_firestore_mapper.dart';

/// The signed-in user's pharmacy, staff and categories from Firestore.
///
/// Reads `pharmacies/{pharmacyId}`, the `users` with that `pharmacyId`, and
/// `pharmacies/{pharmacyId}/categories` with a product count for each.
/// Log out is passed in, so this works with any auth.
class FirestoreAccountRepository implements AccountRepository {
  /// [currentUser] returns who is signed in now; [signOut] signs them out.
  FirestoreAccountRepository({
    required this._currentUser,
    required this._signOut,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final AppUser? Function() _currentUser;
  final Future<void> Function() _signOut;
  final FirebaseFirestore _firestore;

  @override
  Future<PharmacyAccount> load() async {
    final user = _currentUser();
    final pharmacyId = user?.pharmacyId;
    if (user == null || pharmacyId == null) {
      throw StateError('No signed-in user with a pharmacy.');
    }

    final pharmacyRef = _firestore.collection('pharmacies').doc(pharmacyId);
    final (pharmacy, users, categories) = await (
      pharmacyRef.get(),
      _firestore
          .collection('users')
          .where('pharmacyId', isEqualTo: pharmacyId)
          .get(),
      pharmacyRef.collection('categories').get(),
    ).wait;
    if (!pharmacy.exists) throw StateError('The pharmacy does not exist.');

    // One count per category: Firestore charges one read per 1000 products
    // counted, far less than reading the products themselves.
    final counts = await Future.wait([
      for (final category in categories.docs)
        pharmacyRef
            .collection('products')
            .where('categoryId', isEqualTo: category.id)
            .count()
            .get()
            .then((snapshot) => MapEntry(category.id, snapshot.count ?? 0)),
    ]);

    return pharmacyAccountFromFirestore(
      uid: user.uid,
      pharmacy: (id: pharmacy.id, data: pharmacy.data() ?? const {}),
      users: [for (final doc in users.docs) (id: doc.id, data: doc.data())],
      categories: [
        for (final doc in categories.docs) (id: doc.id, data: doc.data()),
      ],
      productCounts: Map.fromEntries(counts),
    );
  }

  @override
  Future<void> signOut() => _signOut();
}
