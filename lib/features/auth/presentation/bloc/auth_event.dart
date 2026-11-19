part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Sent once when the app starts: begins following the user stream.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);

  final AppUser? user;

  @override
  List<Object?> get props => [user];
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.pharmacyName,
    required this.pharmacyLocation,
  });

  final String name;
  final String email;
  final String password;
  final String pharmacyName;
  final String pharmacyLocation;

  @override
  List<Object?> get props => [
    name,
    email,
    password,
    pharmacyName,
    pharmacyLocation,
  ];
}

final class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

final class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

final class AuthVerificationEmailResent extends AuthEvent {
  const AuthVerificationEmailResent();
}

final class AuthVerificationChecked extends AuthEvent {
  const AuthVerificationChecked();
}

final class AuthPharmacySetupSubmitted extends AuthEvent {
  const AuthPharmacySetupSubmitted({
    required this.pharmacyName,
    required this.pharmacyLocation,
  });

  final String pharmacyName;
  final String pharmacyLocation;

  @override
  List<Object?> get props => [pharmacyName, pharmacyLocation];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}