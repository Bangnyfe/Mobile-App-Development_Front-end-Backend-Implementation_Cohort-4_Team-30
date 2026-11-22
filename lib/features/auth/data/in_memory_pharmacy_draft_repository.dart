import '../domain/entities/pharmacy_draft.dart';
import '../domain/repositories/pharmacy_draft_repository.dart';

/// Keeps pharmacy drafts in memory only, for tests and as a default;
/// `main.dart` passes `SharedPrefsPharmacyDraftRepository`.
class InMemoryPharmacyDraftRepository implements PharmacyDraftRepository {
  InMemoryPharmacyDraftRepository([
    Map<String, PharmacyDraft> drafts = const {},
  ]) : _drafts = {...drafts};

  final Map<String, PharmacyDraft> _drafts;

  @override
  Future<PharmacyDraft?> load(String uid) async => _drafts[uid];

  @override
  Future<void> save(String uid, PharmacyDraft draft) async =>
      _drafts[uid] = draft;

  @override
  Future<void> clear(String uid) async => _drafts.remove(uid);
}
