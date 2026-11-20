import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/auth/data/auth_backed_account_repository.dart';
import 'package:team30_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:team30_app/features/settings/data/fake_account_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository auth;
  late AuthBackedAccountRepository repository;

  setUp(() {
    auth = _MockAuthRepository();
    repository = AuthBackedAccountRepository(
      details: const FakeAccountRepository(),
      auth: auth,
    );
  });

  test('Log out in Settings signs out through Firebase auth', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});

    await repository.signOut();

    verify(() => auth.signOut()).called(1);
  });

  test('pharmacy details still come from the details repository', () async {
    final account = await repository.load();

    expect(account.pharmacy.name, 'Amani Pharmacy');
    verifyNever(() => auth.signOut());
  });
}
