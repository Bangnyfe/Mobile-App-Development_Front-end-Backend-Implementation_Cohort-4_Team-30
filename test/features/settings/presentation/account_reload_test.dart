import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/domain/user_role.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/features/auth/domain/entities/app_user.dart';
import 'package:team30_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team30_app/features/settings/data/fake_account_repository.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:team30_app/features/settings/domain/entities/pharmacy_account.dart';

import '../../auth/presentation/auth_test_helpers.dart';

/// Counts how often Settings loads the account.
class _CountingAccountRepository extends FakeAccountRepository {
  int loads = 0;

  @override
  Future<PharmacyAccount> load() {
    loads++;
    return super.load();
  }
}

const _eric = AppUser(
  uid: 'u2',
  email: 'eric@gmail.com',
  name: 'Eric',
  emailVerified: true,
);

void main() {
  testWidgets('Settings reloads when the user joins a pharmacy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final bloc = MockAuthBloc();
    final states = StreamController<AuthState>.broadcast();
    addTearDown(states.close);
    whenListen(
      bloc,
      states.stream,
      initialState: const AuthState(
        status: AuthStatus.needsPharmacy,
        user: _eric,
      ),
    );
    final accounts = _CountingAccountRepository();

    await tester.pumpWidget(
      PharmacyApp(
        router: createAppRouter(authBloc: bloc),
        settingsRepository: SharedPrefsSettingsRepository(
          await SharedPreferences.getInstance(),
        ),
        authBloc: bloc,
        accountRepository: accounts,
      ),
    );
    await tester.pump();
    final before = accounts.loads;

    // Same user, now linked to a pharmacy.
    states.add(
      const AuthState(
        status: AuthStatus.authenticated,
        user: AppUser(
          uid: 'u2',
          email: 'eric@gmail.com',
          name: 'Eric',
          emailVerified: true,
          role: UserRole.pharmacist,
          pharmacyId: 'p1',
        ),
      ),
    );
    await tester.pump();

    expect(accounts.loads, greaterThan(before));
  });
}
