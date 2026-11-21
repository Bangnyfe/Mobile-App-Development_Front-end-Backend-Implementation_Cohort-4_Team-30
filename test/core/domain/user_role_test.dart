import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/domain/user_role.dart';

void main() {
  test('reads the roles stored on users/{uid}.role', () {
    expect(UserRole.fromName('owner'), UserRole.owner);
    expect(UserRole.fromName('pharmacist'), UserRole.pharmacist);
  });

  test('a missing or unknown role is null, never a guessed role', () {
    expect(UserRole.fromName(null), isNull);
    expect(UserRole.fromName('staff'), isNull);
    expect(UserRole.fromName('admin'), isNull);
    expect(UserRole.fromName('Owner'), isNull);
  });

  test('has a label to show on screen', () {
    expect(UserRole.owner.label, 'Owner');
    expect(UserRole.pharmacist.label, 'Pharmacist');
  });
}
