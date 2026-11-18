import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_failure.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_error_messages.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Future<void>? _googleInit;

  static const _users = 'users';
  static const _pharmacies = 'pharmacies';

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(_users).doc(uid);

  @override
  Stream<AppUser?> watchUser() {
    late final StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    profileSubscription;

    controller = StreamController<AppUser?>(
      onListen: () {
        authSubscription = _auth.authStateChanges().listen((user) {
          profileSubscription?.cancel();
          profileSubscription = null;
          if (user == null) {
            controller.add(null);
            return;
          }
          profileSubscription = _userDoc(user.uid).snapshots().listen(
            (doc) => controller.add(_toAppUser(user, doc.data())),
            onError: (Object error, StackTrace stack) {
              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                return;
              }
              controller.addError(error, stack);
            },
          );
        }, onError: controller.addError);
      },
      onCancel: () async {
        await profileSubscription?.cancel();
        await authSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _loadAppUser(credential.user!);
  });

  @override
  Future<AppUser> registerOwner({
    required String name,
    required String email,
    required String password,
    required String pharmacyName,
    required String pharmacyLocation,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name.trim());

    final profile = await _createPharmacyAndProfile(
      user: user,
      name: name.trim(),
      pharmacyName: pharmacyName,
      pharmacyLocation: pharmacyLocation,
    );

    await user.sendEmailVerification();
    return _toAppUser(user, profile);
  });

  @override
  Future<AppUser?> signInWithGoogle() => _guard(() async {
    await (_googleInit ??= _googleSignIn.initialize());

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      // Closing the account picker is a choice, not an error.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw const AuthFailure(
        'Google sign-in did not complete. Please try again.',
      );
    }

    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    return _loadAppUser(result.user!);
  });

  @override
  Future<AppUser> createPharmacy({
    required String pharmacyName,
    required String pharmacyLocation,
  }) => _guard(() async {
    final user = _requireUser();
    final profile = await _createPharmacyAndProfile(
      user: user,
      name: user.displayName ?? _nameFromEmail(user.email),
      pharmacyName: pharmacyName,
      pharmacyLocation: pharmacyLocation,
    );
    return _toAppUser(user, profile);
  });

  @override
  Future<void> sendPasswordResetEmail(String email) => _guard(() async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
      rethrow;
    }
  });

  @override
  Future<void> resendVerificationEmail() =>
      _guard(() => _requireUser().sendEmailVerification());

  @override
  Future<AppUser> reloadUser() => _guard(() async {
    await _requireUser().reload();
    return _loadAppUser(_requireUser());
  });

  @override
  Future<void> signOut() => _guard(() async {
    try {
      await (_googleInit ??= _googleSignIn.initialize());
      await _googleSignIn.signOut();
    } on Object catch (_) {
      // Ignore Google sign-out errors, as they don't prevent Firebase sign-out.
    }
    await _auth.signOut();
  });

  Future<Map<String, dynamic>> _createPharmacyAndProfile({
    required User user,
    required String name,
    required String pharmacyName,
    required String pharmacyLocation,
  }) async {
    final pharmacyRef = _firestore.collection(_pharmacies).doc();
    final profile = <String, dynamic>{
      'name': name,
      'email': user.email ?? '',
      'role': UserRole.owner.name,
      'pharmacyId': pharmacyRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch()
      ..set(pharmacyRef, {
        'name': pharmacyName.trim(),
        'location': pharmacyLocation.trim(),
        'ownerId': user.uid,
      })
      ..set(_userDoc(user.uid), profile);
    await batch.commit();
    return profile;
  }

  Future<AppUser> _loadAppUser(User user) async {
    final doc = await _userDoc(user.uid).get();
    return _toAppUser(user, doc.data());
  }

  AppUser _toAppUser(User user, Map<String, dynamic>? profile) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      name:
          profile?['name'] as String? ??
          user.displayName ??
          _nameFromEmail(user.email),
      emailVerified: user.emailVerified,
      role: profile == null
          ? null
          : UserRole.fromName(profile['role'] as String?),
      pharmacyId: profile?['pharmacyId'] as String?,
    );
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('Your session has ended. Please sign in again.');
    }
    return user;
  }

  static String _nameFromEmail(String? email) =>
      (email ?? '').split('@').first;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authErrorMessage(e.code));
    } on FirebaseException catch (e) {
      throw AuthFailure(authErrorMessage(e.code));
    }
  }
}