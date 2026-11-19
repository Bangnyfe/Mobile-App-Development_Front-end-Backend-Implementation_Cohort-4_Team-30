import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/auth/domain/auth_failure.dart';
import 'package:team30_app/features/auth/domain/entities/app_user.dart';
import 'package:team30_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:team30_app/features/auth/presentation/bloc/auth_bloc.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _unverified = AppUser(
  uid: 'u1',
  email: 'aline@amanipharmacy.rw',
  name: 'Aline',
  emailVerified: false,
  role: UserRole.owner,
  pharmacyId: 'p1',
);

const _owner = AppUser(
  uid: 'u1',
  email: 'aline@amanipharmacy.rw',
  name: 'Aline',
  emailVerified: true,
  role: UserRole.owner,
  pharmacyId: 'p1',
);

const _googleNoPharmacy = AppUser(
  uid: 'u2',
  email: 'eric@gmail.com',
  name: 'Eric',
  emailVerified: true,
);

void main() {
  late _MockAuthRepository repository;

  setUp(() => repository = _MockAuthRepository());

  group('AuthStatus.fromUser', () {
    test('maps each kind of user to the right screen', () {
      expect(AuthStatus.fromUser(null), AuthStatus.unauthenticated);
      expect(AuthStatus.fromUser(_unverified), AuthStatus.needsVerification);
      expect(AuthStatus.fromUser(_googleNoPharmacy), AuthStatus.needsPharmacy);
      expect(AuthStatus.fromUser(_owner), AuthStatus.authenticated);
    });
  });

  test('starts with an unknown session', () {
    expect(AuthBloc(repository).state, const AuthState());
  });

  blocTest<AuthBloc, AuthState>(
    'follows the user stream after AuthStarted',
    setUp: () => when(() => repository.watchUser())
        .thenAnswer((_) => Stream.fromIterable([null, _unverified, _owner])),
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => const [
      AuthState(status: AuthStatus.unauthenticated),
      AuthState(status: AuthStatus.needsVerification, user: _unverified),
      AuthState(status: AuthStatus.authenticated, user: _owner),
    ],
  );

  group('sign in', () {
    blocTest<AuthBloc, AuthState>(
      'shows progress, then becomes authenticated',
      setUp: () => when(
        () => repository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _owner),
      build: () => AuthBloc(repository),
      act: (bloc) => bloc.add(
        const AuthSignInRequested(
          email: 'aline@amanipharmacy.rw',
          password: 'pharmacy2026',
        ),
      ),
      expect: () => const [
        AuthState(
          action: AuthAction.signIn,
          actionStatus: ActionStatus.inProgress,
        ),
        AuthState(
          status: AuthStatus.authenticated,
          user: _owner,
          action: AuthAction.signIn,
          actionStatus: ActionStatus.success,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'shows the failure message and stays signed out',
      setUp: () => when(
        () => repository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure('That email and password do not match.')),
      build: () => AuthBloc(repository),
      seed: () => const AuthState(status: AuthStatus.unauthenticated),
      act: (bloc) => bloc.add(
        const AuthSignInRequested(email: 'a@b.rw', password: 'wrong'),
      ),
      expect: () => const [
        AuthState(
          status: AuthStatus.unauthenticated,
          action: AuthAction.signIn,
          actionStatus: ActionStatus.inProgress,
        ),
        AuthState(
          status: AuthStatus.unauthenticated,
          action: AuthAction.signIn,
          actionStatus: ActionStatus.failure,
          message: 'That email and password do not match.',
        ),
      ],
    );
  });

  blocTest<AuthBloc, AuthState>(
    'registering sends the new owner to email verification',
    setUp: () => when(
      () => repository.registerOwner(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        pharmacyName: any(named: 'pharmacyName'),
        pharmacyLocation: any(named: 'pharmacyLocation'),
      ),
    ).thenAnswer((_) async => _unverified),
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(
      const AuthRegisterRequested(
        name: 'Aline',
        email: 'aline@amanipharmacy.rw',
        password: 'pharmacy2026',
        pharmacyName: 'Amani Pharmacy',
        pharmacyLocation: 'Nyarugenge, Kigali',
      ),
    ),
    expect: () => const [
      AuthState(
        action: AuthAction.register,
        actionStatus: ActionStatus.inProgress,
      ),
      AuthState(
        status: AuthStatus.needsVerification,
        user: _unverified,
        action: AuthAction.register,
        actionStatus: ActionStatus.success,
      ),
    ],
  );

  group('Google sign-in', () {
    blocTest<AuthBloc, AuthState>(
      'a first-time Google user is sent to pharmacy setup',
      setUp: () =>
          when(() => repository.signInWithGoogle())
              .thenAnswer((_) async => _googleNoPharmacy),
      build: () => AuthBloc(repository),
      act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
      expect: () => const [
        AuthState(
          action: AuthAction.google,
          actionStatus: ActionStatus.inProgress,
        ),
        AuthState(
          status: AuthStatus.needsPharmacy,
          user: _googleNoPharmacy,
          action: AuthAction.google,
          actionStatus: ActionStatus.success,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'closing the account picker shows no error',
      setUp: () =>
          when(() => repository.signInWithGoogle())
              .thenAnswer((_) async => null),
      build: () => AuthBloc(repository),
      act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
      expect: () => const [
        AuthState(
          action: AuthAction.google,
          actionStatus: ActionStatus.inProgress,
        ),
        AuthState(action: AuthAction.google),
      ],
    );
  });

  blocTest<AuthBloc, AuthState>(
    'a password reset always shows the same neutral message',
    setUp: () =>
        when(() => repository.sendPasswordResetEmail(any()))
            .thenAnswer((_) async {}),
    build: () => AuthBloc(repository),
    act: (bloc) =>
        bloc.add(const AuthPasswordResetRequested('aline@amanipharmacy.rw')),
    expect: () => const [
      AuthState(
        action: AuthAction.passwordReset,
        actionStatus: ActionStatus.inProgress,
      ),
      AuthState(
        action: AuthAction.passwordReset,
        actionStatus: ActionStatus.success,
        message: AuthBloc.resetSentMessage,
      ),
    ],
  );

  group('verification check', () {
    blocTest<AuthBloc, AuthState>(
      'explains what to do when the email is still unverified',
      setUp: () =>
          when(() => repository.reloadUser())
              .thenAnswer((_) async => _unverified),
      build: () => AuthBloc(repository),
      seed: () => const AuthState(
        status: AuthStatus.needsVerification,
        user: _unverified,
      ),
      act: (bloc) => bloc.add(const AuthVerificationChecked()),
      expect: () => const [
        AuthState(
          status: AuthStatus.needsVerification,
          user: _unverified,
          action: AuthAction.checkVerification,
          actionStatus: ActionStatus.inProgress,
        ),
        AuthState(
          status: AuthStatus.needsVerification,
          user: _unverified,
          action: AuthAction.checkVerification,
          actionStatus: ActionStatus.failure,
          message: AuthBloc.verificationPendingMessage,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'moves on once the email is verified',
      setUp: () =>
          when(() => repository.reloadUser()).thenAnswer((_) async => _owner),
      build: () => AuthBloc(repository),
      seed: () => const AuthState(
        status: AuthStatus.needsVerification,
        user: _unverified,
      ),
      act: (bloc) => bloc.add(const AuthVerificationChecked()),
      expect: () => const [
        AuthState(
          status: AuthStatus.needsVerification,
          user: _unverified,
          action: AuthAction.checkVerification,
          actionStatus: ActionStatus.inProgress,
        ),
        AuthState(
          status: AuthStatus.authenticated,
          user: _owner,
          action: AuthAction.checkVerification,
          actionStatus: ActionStatus.success,
        ),
      ],
    );
  });

  blocTest<AuthBloc, AuthState>(
    'signing out clears the previous user completely',
    setUp: () => when(() => repository.signOut()).thenAnswer((_) async {}),
    build: () => AuthBloc(repository),
    seed: () => const AuthState(status: AuthStatus.authenticated, user: _owner),
    act: (bloc) => bloc.add(const AuthSignOutRequested()),
    expect: () => const [
      AuthState(
        status: AuthStatus.authenticated,
        user: _owner,
        action: AuthAction.signOut,
        actionStatus: ActionStatus.inProgress,
      ),
      AuthState(status: AuthStatus.unauthenticated),
    ],
    verify: (_) => verify(() => repository.signOut()).called(1),
  );
}