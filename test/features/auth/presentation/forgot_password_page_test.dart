import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team30_app/features/auth/presentation/pages/forgot_password_page.dart';

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

  testWidgets('an invalid email is caught before sending', (tester) async {
    await pumpAuthPage(tester, bloc: bloc, page: const ForgotPasswordPage());
    await fillFields(tester, ['aline@']);
    await tapText(tester, 'Send reset link');

    expect(find.textContaining('valid email address'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('a valid email requests a reset link', (tester) async {
    await pumpAuthPage(tester, bloc: bloc, page: const ForgotPasswordPage());
    await fillFields(tester, [' aline@amanipharmacy.rw ']);
    await tapText(tester, 'Send reset link');

    verify(
      () =>
          bloc.add(const AuthPasswordResetRequested('aline@amanipharmacy.rw')),
    ).called(1);
  });

  testWidgets('shows the neutral confirmation after sending', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable(const [
        AuthState(
          status: AuthStatus.unauthenticated,
          action: AuthAction.passwordReset,
          actionStatus: ActionStatus.success,
          message: AuthBloc.resetSentMessage,
        ),
      ]),
      initialState: const AuthState(status: AuthStatus.unauthenticated),
    );
    await pumpAuthPage(tester, bloc: bloc, page: const ForgotPasswordPage());
    await tester.pump();

    expect(find.text(AuthBloc.resetSentMessage), findsOneWidget);
  });
}
