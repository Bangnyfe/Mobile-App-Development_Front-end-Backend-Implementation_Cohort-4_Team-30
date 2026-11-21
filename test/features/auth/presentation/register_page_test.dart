import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team30_app/features/auth/presentation/pages/register_page.dart';

import 'auth_test_helpers.dart';

void main() {
  late MockAuthBloc bloc;

  setUpAll(() => registerFallbackValue(const AuthStarted()));

  setUp(() {
    bloc = MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(status: AuthStatus.unauthenticated),
    );
  });

  testWidgets('a blank form shows an error for every field', (tester) async {
    await pumpAuthPage(tester, bloc: bloc, page: const RegisterPage());
    await tapText(tester, 'Create account');

    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Choose a password.'), findsOneWidget);
    expect(find.text('Re-enter your password.'), findsOneWidget);
    expect(find.text('Enter the pharmacy name.'), findsOneWidget);
    expect(find.text('Enter the location.'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('mismatched passwords stop registration', (tester) async {
    await pumpAuthPage(tester, bloc: bloc, page: const RegisterPage());
    await fillFields(tester, [
      'Aline Uwase',
      'aline@amanipharmacy.rw',
      'pharmacy2026',
      'pharmacy2025',
      'Amani Pharmacy',
      'Gasabo, Kigali',
    ]);
    await tapText(tester, 'Create account');

    expect(find.text('Passwords do not match.'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('a valid form registers with trimmed values', (tester) async {
    await pumpAuthPage(tester, bloc: bloc, page: const RegisterPage());
    await fillFields(tester, [
      ' Aline Uwase ',
      'aline@amanipharmacy.rw ',
      'pharmacy2026',
      'pharmacy2026',
      ' Amani Pharmacy',
      'Gasabo, Kigali ',
    ]);
    await tapText(tester, 'Create account');

    verify(
      () => bloc.add(
        const AuthRegisterRequested(
          name: 'Aline Uwase',
          email: 'aline@amanipharmacy.rw',
          password: 'pharmacy2026',
          pharmacyName: 'Amani Pharmacy',
          pharmacyLocation: 'Gasabo, Kigali',
        ),
      ),
    ).called(1);
  });
}
