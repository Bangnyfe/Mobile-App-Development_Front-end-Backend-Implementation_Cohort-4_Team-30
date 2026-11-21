import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/auth/domain/entities/app_user.dart';
import 'package:team30_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team30_app/features/auth/presentation/pages/pharmacy_setup_page.dart';

import 'auth_test_helpers.dart';

const _googleUser = AppUser(
  uid: 'u2',
  email: 'eric@gmail.com',
  name: 'Eric',
  emailVerified: true,
);

void main() {
  late MockAuthBloc bloc;

  setUpAll(() => registerFallbackValue(const AuthStarted()));

  setUp(() {
    bloc = MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.needsPharmacy,
        user: _googleUser,
      ),
    );
  });

  testWidgets('shows the signed-in account and requires both fields', (
    tester,
  ) async {
    await pumpAuthPage(tester, bloc: bloc, page: const PharmacySetupPage());
    expect(find.textContaining('eric@gmail.com'), findsOneWidget);

    await tapText(tester, 'Continue');

    expect(find.text('Enter the pharmacy name.'), findsOneWidget);
    expect(find.text('Enter the location.'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('a valid form creates the pharmacy', (tester) async {
    await pumpAuthPage(tester, bloc: bloc, page: const PharmacySetupPage());
    await fillFields(tester, [' Kacyiru Pharmacy ', 'Gasabo, Kigali']);
    await tapText(tester, 'Continue');

    verify(
      () => bloc.add(
        const AuthPharmacySetupSubmitted(
          pharmacyName: 'Kacyiru Pharmacy',
          pharmacyLocation: 'Gasabo, Kigali',
        ),
      ),
    ).called(1);
  });
}
