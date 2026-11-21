import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/auth_failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthVerificationEmailResent>(_onVerificationResent);
    on<AuthVerificationChecked>(_onVerificationChecked);
    on<AuthPharmacySetupSubmitted>(_onPharmacySetup);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _userSubscription;

  static const verificationPendingMessage =
      'Your email is not verified yet. Open the link we sent, then tap '
      'the button again.';
  static const resetSentMessage =
      'If an account exists for that email, we have sent a reset link.';
  static const verificationSentMessage = 'We sent a new verification email.';

  void _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    _userSubscription?.cancel();
    _userSubscription = _repository.watchUser().listen(
      (user) => add(_AuthUserChanged(user)),
      onError: (Object _) {
        // Keep the last known session on a stream error (for example a
        // brief network drop) instead of signing the user out of the UI.
      },
    );
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    emit(state.withUser(event.user));
  }

  Future<void> _onSignIn(AuthSignInRequested event, Emitter<AuthState> emit) =>
      _runForUser(
        emit,
        AuthAction.signIn,
        () => _repository.signInWithEmail(
          email: event.email,
          password: event.password,
        ),
      );

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) => _runForUser(
    emit,
    AuthAction.register,
    () => _repository.registerOwner(
      name: event.name,
      email: event.email,
      password: event.password,
      pharmacyName: event.pharmacyName,
      pharmacyLocation: event.pharmacyLocation,
    ),
  );

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.withAction(AuthAction.google, ActionStatus.inProgress));
    try {
      final user = await _repository.signInWithGoogle();
      if (user == null) {
        // The user closed the account picker: no error to show.
        emit(state.withAction(AuthAction.google, ActionStatus.idle));
        return;
      }
      emit(
        state
            .withUser(user)
            .withAction(AuthAction.google, ActionStatus.success),
      );
    } on AuthFailure catch (failure) {
      emit(
        state.withAction(
          AuthAction.google,
          ActionStatus.failure,
          message: failure.message,
        ),
      );
    }
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) => _run(
    emit,
    AuthAction.passwordReset,
    () => _repository.sendPasswordResetEmail(event.email),
    successMessage: resetSentMessage,
  );

  Future<void> _onVerificationResent(
    AuthVerificationEmailResent event,
    Emitter<AuthState> emit,
  ) => _run(
    emit,
    AuthAction.resendVerification,
    _repository.resendVerificationEmail,
    successMessage: verificationSentMessage,
  );

  Future<void> _onVerificationChecked(
    AuthVerificationChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.withAction(AuthAction.checkVerification, ActionStatus.inProgress),
    );
    try {
      final user = await _repository.reloadUser();
      final verified = user.emailVerified;
      emit(
        state
            .withUser(user)
            .withAction(
              AuthAction.checkVerification,
              verified ? ActionStatus.success : ActionStatus.failure,
              message: verified ? null : verificationPendingMessage,
            ),
      );
    } on AuthFailure catch (failure) {
      emit(
        state.withAction(
          AuthAction.checkVerification,
          ActionStatus.failure,
          message: failure.message,
        ),
      );
    }
  }

  Future<void> _onPharmacySetup(
    AuthPharmacySetupSubmitted event,
    Emitter<AuthState> emit,
  ) => _runForUser(
    emit,
    AuthAction.pharmacySetup,
    () => _repository.createPharmacy(
      pharmacyName: event.pharmacyName,
      pharmacyLocation: event.pharmacyLocation,
    ),
  );

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.withAction(AuthAction.signOut, ActionStatus.inProgress));
    try {
      await _repository.signOut();
      // A brand-new state, so nothing from the previous user is kept.
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } on AuthFailure catch (failure) {
      emit(
        state.withAction(
          AuthAction.signOut,
          ActionStatus.failure,
          message: failure.message,
        ),
      );
    }
  }

  Future<void> _runForUser(
    Emitter<AuthState> emit,
    AuthAction action,
    Future<AppUser> Function() call,
  ) async {
    emit(state.withAction(action, ActionStatus.inProgress));
    try {
      final user = await call();
      emit(state.withUser(user).withAction(action, ActionStatus.success));
    } on AuthFailure catch (failure) {
      emit(
        state.withAction(
          action,
          ActionStatus.failure,
          message: failure.message,
        ),
      );
    }
  }

  /// Runs an action that does not change the user.
  Future<void> _run(
    Emitter<AuthState> emit,
    AuthAction action,
    Future<void> Function() call, {
    String? successMessage,
  }) async {
    emit(state.withAction(action, ActionStatus.inProgress));
    try {
      await call();
      emit(
        state.withAction(action, ActionStatus.success, message: successMessage),
      );
    } on AuthFailure catch (failure) {
      emit(
        state.withAction(
          action,
          ActionStatus.failure,
          message: failure.message,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _userSubscription?.cancel();
    return super.close();
  }
}
