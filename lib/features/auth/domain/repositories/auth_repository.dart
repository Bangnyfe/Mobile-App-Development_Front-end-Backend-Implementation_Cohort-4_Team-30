import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> watchUser();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates the account and the owner's pharmacy, then sends the
  /// verification email.
  Future<AppUser> registerOwner({
    required String name,
    required String email,
    required String password,
    required String pharmacyName,
    required String pharmacyLocation,
  });

  /// Returns null if the user closes the Google account picker.
  Future<AppUser?> signInWithGoogle();

  Future<AppUser> createPharmacy({
    required String pharmacyName,
    required String pharmacyLocation,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> resendVerificationEmail();

  Future<AppUser> reloadUser();

  Future<void> signOut();
}