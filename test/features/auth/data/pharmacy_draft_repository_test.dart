import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/features/auth/data/in_memory_pharmacy_draft_repository.dart';
import 'package:team30_app/features/auth/data/shared_prefs_pharmacy_draft_repository.dart';
import 'package:team30_app/features/auth/domain/entities/pharmacy_draft.dart';
import 'package:team30_app/features/auth/domain/repositories/pharmacy_draft_repository.dart';

const _draft = PharmacyDraft(name: 'Amani Pharmacy', location: 'Nyarugenge');

void main() {
  final implementations = <String, Future<PharmacyDraftRepository> Function()>{
    'SharedPreferences': () async {
      SharedPreferences.setMockInitialValues({});
      return SharedPrefsPharmacyDraftRepository(
        await SharedPreferences.getInstance(),
      );
    },
    'in memory': () async => InMemoryPharmacyDraftRepository(),
  };

  for (final MapEntry(key: name, value: create) in implementations.entries) {
    group(name, () {
      test('has no draft for a new account', () async {
        final repository = await create();

        expect(await repository.load('u1'), isNull);
      });

      test('a saved draft loads back for the same account only', () async {
        final repository = await create();

        await repository.save('u1', _draft);

        expect(await repository.load('u1'), _draft);
        expect(await repository.load('u2'), isNull);
      });

      test('clear forgets the draft', () async {
        final repository = await create();
        await repository.save('u1', _draft);

        await repository.clear('u1');

        expect(await repository.load('u1'), isNull);
      });
    });
  }
}
