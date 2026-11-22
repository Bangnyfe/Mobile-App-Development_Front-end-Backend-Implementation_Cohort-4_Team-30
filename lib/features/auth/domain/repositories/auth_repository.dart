import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> watchUser();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates the account and sends the verification email.
  ///
  /// The pharmacy details are only remembered (see
  /// `PharmacyDraftRepository`). The pharmacy is created after
  /// verification, at the setup step, where an invited pharmacist can
  /// join their pharmacy instead.
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

  /// Fetches the latest account state, e.g. after the user opened the
  /// verification link.
  Future<AppUser> reloadUser();

  Future<void> signOut();
}
