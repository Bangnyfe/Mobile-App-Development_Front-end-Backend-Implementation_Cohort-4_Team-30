import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/core/domain/user_role.dart';
import 'package:team30_app/features/auth/data/firebase_auth_repository.dart';
import 'package:team30_app/features/auth/data/in_memory_pharmacy_draft_repository.dart';
import 'package:team30_app/features/auth/domain/entities/pharmacy_draft.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

// Firestore's types are sealed, but mocking them is the usual way to
// test code that reads a document.
// ignore: subtype_of_sealed_class
class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late _MockAuth auth;
  late _MockFirestore firestore;
  late _MockUser user;
  late InMemoryPharmacyDraftRepository drafts;
  late FirebaseAuthRepository repository;

  setUp(() {
    auth = _MockAuth();
    firestore = _MockFirestore();
    user = _MockUser();
    drafts = InMemoryPharmacyDraftRepository();
    repository = FirebaseAuthRepository(
      auth: auth,
      firestore: firestore,
      googleSignIn: _MockGoogleSignIn(),
      drafts: drafts,
    );

    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('aline@amanipharmacy.rw');
  });

  group('registerOwner', () {
    setUp(() {
      final credential = _MockCredential();
      when(() => credential.user).thenReturn(user);
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);
      when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => user.sendEmailVerification()).thenAnswer((_) async {});
    });

    Future<void> register() => repository.registerOwner(
      name: ' Aline Uwase ',
      email: ' aline@amanipharmacy.rw ',
      password: 'secret123',
      pharmacyName: ' Amani Pharmacy ',
      pharmacyLocation: ' Nyarugenge, Kigali ',
    );

    test('creates the account and sends the verification email', () async {
      await register();

      verify(
        () => auth.createUserWithEmailAndPassword(
          email: 'aline@amanipharmacy.rw',
          password: 'secret123',
        ),
      ).called(1);
      verify(() => user.updateDisplayName('Aline Uwase')).called(1);
      verify(() => user.sendEmailVerification()).called(1);
    });

    test('remembers the pharmacy instead of creating it', () async {
      final registered = await repository.registerOwner(
        name: 'Aline Uwase',
        email: 'aline@amanipharmacy.rw',
        password: 'secret123',
        pharmacyName: ' Amani Pharmacy ',
        pharmacyLocation: ' Nyarugenge, Kigali ',
      );

      expect(
        await drafts.load('u1'),
        const PharmacyDraft(
          name: 'Amani Pharmacy',
          location: 'Nyarugenge, Kigali',
        ),
      );
      // Nothing is written until the email is verified.
      verifyZeroInteractions(firestore);
      expect(registered.hasPharmacy, isFalse);
      expect(registered.emailVerified, isFalse);
      expect(registered.name, 'Aline Uwase');
    });
  });

  group('reloadUser', () {
    setUp(() {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.reload()).thenAnswer((_) async {});
      when(() => user.displayName).thenReturn('Aline Uwase');
      when(() => user.getIdToken(any())).thenAnswer((_) async => 'token');

      final users = _MockCollection();
      final doc = _MockDocument();
      final snapshot = _MockSnapshot();
      when(() => firestore.collection('users')).thenReturn(users);
      when(() => users.doc('u1')).thenReturn(doc);
      when(() => doc.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.data()).thenReturn({
        'name': 'Aline Uwase',
        'role': 'owner',
        'pharmacyId': 'p1',
      });
    });

    test('refreshes the token once the email is verified', () async {
      when(() => user.emailVerified).thenReturn(true);

      final reloaded = await repository.reloadUser();

      verify(() => user.getIdToken(true)).called(1);
      expect(reloaded.emailVerified, isTrue);
      expect(reloaded.role, UserRole.owner);
      expect(reloaded.pharmacyId, 'p1');
    });

    test('leaves the token alone while still unverified', () async {
      when(() => user.emailVerified).thenReturn(false);

      await repository.reloadUser();

      verifyNever(() => user.getIdToken(any()));
    });
  });
}
