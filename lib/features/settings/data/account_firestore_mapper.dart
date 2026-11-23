import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/user_role.dart';
import '../domain/entities/pharmacy_account.dart';

/// A document's ID and data, as read from Firestore.
typedef FirestoreDoc = ({String id, Map<String, dynamic> data});

/// Builds the Settings account from the `pharmacies/{pharmacyId}`
/// document, the `users` of that pharmacy and its `categories`, using the
/// field names from the ERD.
///
/// [productCounts] maps a category ID to how many products use it.
///
/// Throws a [StateError] if the signed-in user ([uid]) isn't among [users],
/// which means their profile and pharmacy don't match.
PharmacyAccount pharmacyAccountFromFirestore({
  required String uid,
  required FirestoreDoc pharmacy,
  required Iterable<FirestoreDoc> users,
  required Iterable<FirestoreDoc> categories,
  Map<String, int> productCounts = const {},
}) {
  final staff = [for (final doc in users) _staffMember(doc)]
    ..sort((a, b) {
      // The owner first, then everyone else by name.
      if (a.isOwner != b.isOwner) return a.isOwner ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  final user = staff.where((member) => member.id == uid).firstOrNull;
  if (user == null) {
    throw StateError('The signed-in user is not a member of this pharmacy.');
  }

  return PharmacyAccount(
    pharmacy: _pharmacy(pharmacy),
    user: user,
    staff: staff,
    categories: [
      for (final doc in categories)
        ProductCategory(
          id: doc.id,
          name: _string(doc.data['name']),
          productCount: productCounts[doc.id] ?? 0,
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
  );
}

/// The fields an owner edits on `pharmacies/{pharmacyId}`, trimmed. An
/// empty phone or address is deleted rather than saved blank, and the old
/// single `location` field goes, now that district and city are saved.
Map<String, Object> pharmacyProfileToFirestore(Pharmacy pharmacy) {
  String? optional(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  return {
    'name': pharmacy.name.trim(),
    'district': pharmacy.district.trim(),
    'city': pharmacy.city.trim(),
    'phone': optional(pharmacy.phone) ?? FieldValue.delete(),
    'address': optional(pharmacy.address) ?? FieldValue.delete(),
    'location': FieldValue.delete(),
  };
}

Pharmacy _pharmacy(FirestoreDoc doc) {
  final data = doc.data;
  var district = _string(data['district']);
  // Pharmacies created before district and city existed saved one
  // `location`; show it as the district until the owner edits it.
  if (district.isEmpty) district = _string(data['location']);
  return Pharmacy(
    id: doc.id,
    name: _string(data['name']),
    district: district,
    city: _string(data['city']),
    phone: _optional(data['phone']),
    address: _optional(data['address']),
  );
}

StaffMember _staffMember(FirestoreDoc doc) => StaffMember(
  id: doc.id,
  name: _string(doc.data['name']),
  email: _string(doc.data['email']),
  // Anyone without a known role gets the one with fewer permissions.
  role: UserRole.fromName(doc.data['role'] as String?) ?? UserRole.pharmacist,
);

String _string(Object? value) => value is String ? value.trim() : '';

String? _optional(Object? value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
}
