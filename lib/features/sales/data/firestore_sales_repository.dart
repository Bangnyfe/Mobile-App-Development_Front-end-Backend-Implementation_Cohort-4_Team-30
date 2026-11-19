import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/sale.dart';
import '../domain/repositories/sales_repository.dart';
import 'sale_firestore_mapper.dart';

/// Reads the sales that checkout saves in `pharmacies/{pharmacyId}/sales`.
class FirestoreSalesRepository implements SalesRepository {
  FirestoreSalesRepository({
    required this.pharmacyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String pharmacyId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sales => _firestore
      .collection('pharmacies')
      .doc(pharmacyId)
      .collection('sales');

  @override
  Stream<List<Sale>> watchSales({
    int limit = SalesRepository.defaultLimit,
  }) {
    return _sales
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              saleFromFirestore(doc.id, _data(doc)),
          ],
        );
  }

  @override
  Future<Sale?> getSale(String saleId) async {
    final doc = await _sales.doc(saleId).get();
    if (!doc.exists) return null;
    return saleFromFirestore(doc.id, _data(doc));
  }

  /// A sale saved on this phone moments ago has no server time yet; its
  /// `createdAt` reads as null and the mapper uses the current time instead.
  Map<String, dynamic> _data(DocumentSnapshot<Map<String, dynamic>> doc) =>
      doc.data() ?? const {};
}
