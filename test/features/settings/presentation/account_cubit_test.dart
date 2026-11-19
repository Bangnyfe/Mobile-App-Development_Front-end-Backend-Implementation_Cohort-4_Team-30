import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/settings/data/fake_account_repository.dart';
import 'package:team30_app/features/settings/presentation/cubit/account_cubit.dart';

import '../settings_test_helpers.dart';

void main() {
  test('starts loading', () {
    expect(AccountCubit(TestAccountRepository()).state, const AccountLoading());
  });

  blocTest<AccountCubit, AccountState>(
    'load emits the account',
    build: () => AccountCubit(TestAccountRepository()),
    act: (cubit) => cubit.load(),
    expect: () => [
      const AccountLoading(),
      isA<AccountLoaded>().having(
        (state) => state.account.pharmacy.name,
        'pharmacy',
        'Amani Pharmacy',
      ),
    ],
  );

  blocTest<AccountCubit, AccountState>(
    'load emits a failure when the repository throws',
    build: () => AccountCubit(TestAccountRepository(fail: true)),
    act: (cubit) => cubit.load(),
    expect: () => [
      const AccountLoading(),
      const AccountFailure(AccountCubit.loadFailedMessage),
    ],
  );

  test('signOut goes through the repository', () async {
    final repository = TestAccountRepository();

    await AccountCubit(repository).signOut();

    expect(repository.signOutCount, 1);
  });

  test('the sample account has one owner among three staff', () async {
    final account = await const FakeAccountRepository().load();

    expect(account.user.isOwner, isTrue);
    expect(account.staff, hasLength(3));
    expect(account.staff.where((member) => member.isOwner), hasLength(1));
    expect(account.categories, hasLength(14));
  });
}
