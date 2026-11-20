import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/auth/domain/entities/app_user.dart';
import 'package:team30_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team30_app/features/auth/presentation/pages/verify_email_page.dart';

import 'auth_test_helpers.dart';

const _unverified = AppUser(
  uid: 'u1',
  email: 'aline@amanipharmacy.rw',
  name: 'Aline',
  emailVerified: false,
  role: UserRole.owner,
  pharmacyId: 'p1',
);

void main() {
  late MockAuthBloc bloc;

  setUp(() {
    bloc = MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.needsVerification,
        user: _unverified,
      ),
    );
  });

  testWidgets('tells the user which address the link went to', (tester) async {
    await pumpAuthPage(tester, bloc: bloc, page: const VerifyEmailPage());

    expect(find.textContaining('aline@amanipharmacy.rw'), findsOneWidget);
  });

  testWidgets('each button sends its event', (tester) async {
    await pumpAuthPage(tester, bloc: bloc, page: const VerifyEmailPage());

    await tapText(tester, "I've verified my email");
    verify(() => bloc.add(const AuthVerificationChecked())).called(1);

    await tapText(tester, 'Resend email');
    verify(() => bloc.add(const AuthVerificationEmailResent())).called(1);

    await tapText(tester, 'Use another account');
    verify(() => bloc.add(const AuthSignOutRequested())).called(1);
  });
}
