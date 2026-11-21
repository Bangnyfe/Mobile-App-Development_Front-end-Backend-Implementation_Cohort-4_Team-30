import '../entities/pharmacy_draft.dart';

/// Remembers each account's [PharmacyDraft] on this device, keyed by UID.
///
/// Losing a draft is harmless (e.g. verifying on another phone): the setup
/// form is just empty and the user types the details again.
abstract interface class PharmacyDraftRepository {
  Future<PharmacyDraft?> load(String uid);

  Future<void> save(String uid, PharmacyDraft draft);

  Future<void> clear(String uid);
}
