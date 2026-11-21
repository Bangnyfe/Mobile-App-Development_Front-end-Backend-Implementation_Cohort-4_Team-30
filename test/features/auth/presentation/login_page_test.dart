import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team30_app/features/auth/presentation/pages/login_page.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc bloc;

  setUpAll(() => registerFallbackValue(const AuthStarted()));

  setUp(() {
    bloc = _MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(status: AuthStatus.unauthenticated),
    );
  });

  Future<void> pumpLogin(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AuthBloc>.value(value: bloc, child: const LoginPage()),
    ),
  );

  Future<void> tapSignIn(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Sign in');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  testWidgets('blank fields show error messages and do not sign in', (
    tester,
  ) async {
    await pumpLogin(tester);
    await tapSignIn(tester);

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('a valid form sends the trimmed email and the password', (
    tester,
  ) async {
    await pumpLogin(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  aline@amanipharmacy.rw ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'pharmacy2026');
    await tapSignIn(tester);

    verify(
      () => bloc.add(
        const AuthSignInRequested(
          email: 'aline@amanipharmacy.rw',
          password: 'pharmacy2026',
        ),
      ),
    ).called(1);
  });

  testWidgets('shows a spinner and disables Sign in while signing in', (
    tester,
  ) async {
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.unauthenticated,
        action: AuthAction.signIn,
        actionStatus: ActionStatus.inProgress,
      ),
    );
    await pumpLogin(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows a failed sign-in message in a SnackBar', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable(const [
        AuthState(
          status: AuthStatus.unauthenticated,
          action: AuthAction.signIn,
          actionStatus: ActionStatus.failure,
          message: 'That email and password do not match.',
        ),
      ]),
      initialState: const AuthState(status: AuthStatus.unauthenticated),
    );
    await pumpLogin(tester);
    await tester.pump();

    expect(find.text('That email and password do not match.'), findsOneWidget);
  });
}
