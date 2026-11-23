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

// ignore: subtype_of_sealed_class
class _MockBatch extends Mock implements WriteBatch {}

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
      pharmacyDistrict: ' Nyarugenge ',
      pharmacyCity: ' Kigali ',
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
        pharmacyDistrict: ' Nyarugenge ',
        pharmacyCity: ' Kigali ',
      );

      expect(
        await drafts.load('u1'),
        const PharmacyDraft(
          name: 'Amani Pharmacy',
          district: 'Nyarugenge',
          city: 'Kigali',
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

  group('createPharmacy', () {
    late _MockBatch batch;
    late _MockDocument pharmacyDoc;
    late _MockDocument userDoc;

    setUp(() async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.displayName).thenReturn('Eric');
      when(() => user.emailVerified).thenReturn(true);

      final pharmacies = _MockCollection();
      final users = _MockCollection();
      pharmacyDoc = _MockDocument();
      userDoc = _MockDocument();
      batch = _MockBatch();
      when(() => firestore.collection('pharmacies')).thenReturn(pharmacies);
      when(() => firestore.collection('users')).thenReturn(users);
      when(() => pharmacies.doc()).thenReturn(pharmacyDoc);
      when(() => pharmacyDoc.id).thenReturn('p1');
      when(() => users.doc('u1')).thenReturn(userDoc);
      when(() => firestore.batch()).thenReturn(batch);
      when(() => batch.commit()).thenAnswer((_) async {});
      await drafts.save(
        'u1',
        const PharmacyDraft(
          name: 'Eric Pharmacy',
          district: 'Gasabo',
          city: 'Kigali',
        ),
      );
    });

    test('saves the district, city and the ERD defaults, then clears the '
        'draft', () async {
      final created = await repository.createPharmacy(
        pharmacyName: ' Kacyiru Pharmacy ',
        pharmacyDistrict: ' Gasabo ',
        pharmacyCity: ' Kigali ',
      );

      final pharmacy =
          verify(
                () =>
                    batch.set<Map<String, dynamic>>(pharmacyDoc, captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(pharmacy, containsPair('name', 'Kacyiru Pharmacy'));
      expect(pharmacy, containsPair('district', 'Gasabo'));
      expect(pharmacy, containsPair('city', 'Kigali'));
      expect(pharmacy, containsPair('ownerId', 'u1'));
      expect(pharmacy.containsKey('nextReceiptNo'), isFalse);
      expect(pharmacy, containsPair('defaultReorderLevel', 20));
      expect(pharmacy, containsPair('expiryAlertDays', 90));
      expect(pharmacy.containsKey('location'), isFalse);

      final profile =
          verify(() => batch.set<Map<String, dynamic>>(userDoc, captureAny()))
                  .captured
                  .single
              as Map<String, dynamic>;
      expect(profile, containsPair('role', 'owner'));
      expect(profile, containsPair('pharmacyId', 'p1'));

      expect(created.pharmacyId, 'p1');
      expect(await drafts.load('u1'), isNull);
    });
  });
}
