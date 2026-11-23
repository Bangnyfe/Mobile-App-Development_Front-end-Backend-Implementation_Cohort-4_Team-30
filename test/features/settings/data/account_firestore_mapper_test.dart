import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/domain/user_role.dart';
import 'package:team30_app/features/settings/data/account_firestore_mapper.dart';
import 'package:team30_app/features/settings/domain/entities/pharmacy_account.dart';

const FirestoreDoc _pharmacy = (
  id: 'p1',
  data: {
    'name': 'Amani Pharmacy',
    'district': 'Nyarugenge',
    'city': 'Kigali',
    'phone': '+250 788 000 000',
    'address': ' KN 4 Ave ',
    'ownerId': 'owner-1',
  },
);

const List<FirestoreDoc> _users = [
  (
    id: 'u3',
    data: {'name': 'Diane', 'email': 'diane@gmail.com', 'role': 'pharmacist'},
  ),
  (
    id: 'owner-1',
    data: {'name': 'Aline', 'email': 'aline@amani.rw', 'role': 'owner'},
  ),
  (
    id: 'u2',
    data: {'name': 'eric', 'email': 'eric@gmail.com', 'role': 'pharmacist'},
  ),
];

void main() {
  test('reads the pharmacy with the ERD fields', () {
    final account = pharmacyAccountFromFirestore(
      uid: 'owner-1',
      pharmacy: _pharmacy,
      users: _users,
      categories: const [],
    );

    expect(
      account.pharmacy,
      const Pharmacy(
        id: 'p1',
        name: 'Amani Pharmacy',
        district: 'Nyarugenge',
        city: 'Kigali',
        phone: '+250 788 000 000',
        address: 'KN 4 Ave',
      ),
    );
  });

  test('lists the owner first, then staff by name', () {
    final account = pharmacyAccountFromFirestore(
      uid: 'u2',
      pharmacy: _pharmacy,
      users: _users,
      categories: const [],
    );

    expect(account.staff.map((member) => member.name), [
      'Aline',
      'Diane',
      'eric',
    ]);
    expect(account.staff.first.role, UserRole.owner);
  });

  test('the signed-in user is found among the staff', () {
    final account = pharmacyAccountFromFirestore(
      uid: 'u2',
      pharmacy: _pharmacy,
      users: _users,
      categories: const [],
    );

    expect(
      account.user,
      const StaffMember(
        id: 'u2',
        name: 'eric',
        email: 'eric@gmail.com',
        role: UserRole.pharmacist,
      ),
    );
  });

  test('fails if the signed-in user is not in this pharmacy', () {
    expect(
      () => pharmacyAccountFromFirestore(
        uid: 'stranger',
        pharmacy: _pharmacy,
        users: _users,
        categories: const [],
      ),
      throwsStateError,
    );
  });

  test('categories are sorted by name with their product counts', () {
    final account = pharmacyAccountFromFirestore(
      uid: 'owner-1',
      pharmacy: _pharmacy,
      users: _users,
      categories: const [
        (id: 'c2', data: {'name': 'Antibiotics'}),
        (id: 'c1', data: {'name': 'analgesics'}),
      ],
      productCounts: const {'c2': 52},
    );

    expect(account.categories, const [
      ProductCategory(id: 'c1', name: 'analgesics', productCount: 0),
      ProductCategory(id: 'c2', name: 'Antibiotics', productCount: 52),
    ]);
  });

  test('an older pharmacy shows its single location as the district', () {
    final account = pharmacyAccountFromFirestore(
      uid: 'owner-1',
      pharmacy: const (
        id: 'p1',
        data: {'name': 'Old Pharmacy', 'location': 'Remera, Kigali'},
      ),
      users: _users,
      categories: const [],
    );

    expect(account.pharmacy.district, 'Remera, Kigali');
    expect(account.pharmacy.city, '');
    expect(account.pharmacy.location, 'Remera, Kigali');
    expect(account.pharmacy.phone, isNull);
    expect(account.pharmacy.address, isNull);
  });

  test('an unknown role gets the fewer permissions', () {
    final account = pharmacyAccountFromFirestore(
      uid: 'u9',
      pharmacy: _pharmacy,
      users: const [
        (id: 'u9', data: {'name': 'Someone', 'role': 'admin'}),
      ],
      categories: const [],
    );

    expect(account.user.role, UserRole.pharmacist);
    expect(account.user.email, '');
  });

  group('pharmacyProfileToFirestore', () {
    test('saves the edited fields trimmed', () {
      final fields = pharmacyProfileToFirestore(
        const Pharmacy(
          id: 'p1',
          name: ' Amani Pharmacy ',
          district: ' Gasabo ',
          city: ' Kigali ',
          phone: ' +250 788 111 222 ',
          address: ' KG 7 Ave ',
        ),
      );

      expect(fields['name'], 'Amani Pharmacy');
      expect(fields['district'], 'Gasabo');
      expect(fields['city'], 'Kigali');
      expect(fields['phone'], '+250 788 111 222');
      expect(fields['address'], 'KG 7 Ave');
      expect(fields.containsKey('ownerId'), isFalse);
    });

    test('deletes a missing or blank phone and address, and the old '
        'location', () {
      final fields = pharmacyProfileToFirestore(
        const Pharmacy(
          id: 'p1',
          name: 'Amani Pharmacy',
          district: 'Gasabo',
          city: 'Kigali',
          address: '   ',
        ),
      );

      expect(fields['phone'], isA<FieldValue>());
      expect(fields['address'], isA<FieldValue>());
      expect(fields['location'], isA<FieldValue>());
    });
  });
}
