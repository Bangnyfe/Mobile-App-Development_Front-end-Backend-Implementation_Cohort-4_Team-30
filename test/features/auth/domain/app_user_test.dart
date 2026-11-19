import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/auth/domain/entities/app_user.dart';

void main() {
  const owner = AppUser(
    uid: 'u1',
    email: 'aline@amanipharmacy.rw',
    name: 'Aline',
    emailVerified: false,
    role: UserRole.owner,
    pharmacyId: 'p1',
  );

  test('a user with a profile has a pharmacy and an owner role', () {
    expect(owner.hasPharmacy, isTrue);
    expect(owner.isOwner, isTrue);
  });

  test('a user without a profile has no pharmacy', () {
    const googleUser = AppUser(
      uid: 'u2',
      email: 'eric@gmail.com',
      name: 'Eric',
      emailVerified: true,
    );
    expect(googleUser.hasPharmacy, isFalse);
    expect(googleUser.isOwner, isFalse);
  });

  test('copyWith changes only emailVerified', () {
    final verified = owner.copyWith(emailVerified: true);
    expect(verified.emailVerified, isTrue);
    expect(verified.pharmacyId, owner.pharmacyId);
    expect(verified, isNot(owner));
  });

  test('UserRole.fromName falls back to staff for unknown values', () {
    expect(UserRole.fromName('owner'), UserRole.owner);
    expect(UserRole.fromName('staff'), UserRole.staff);
    expect(UserRole.fromName(null), UserRole.staff);
    expect(UserRole.fromName('admin'), UserRole.staff);
  });
}
