import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/pharmacy_draft.dart';
import '../domain/repositories/pharmacy_draft_repository.dart';

/// Saves pharmacy drafts on the device with SharedPreferences.
class SharedPrefsPharmacyDraftRepository implements PharmacyDraftRepository {
  SharedPrefsPharmacyDraftRepository(this._prefs);

  final SharedPreferences _prefs;

  static String nameKey(String uid) => 'pharmacyDraft.$uid.name';
  static String locationKey(String uid) => 'pharmacyDraft.$uid.location';

  @override
  Future<PharmacyDraft?> load(String uid) async {
    final name = _prefs.getString(nameKey(uid));
    if (name == null) return null;
    return PharmacyDraft(
      name: name,
      location: _prefs.getString(locationKey(uid)) ?? '',
    );
  }

  @override
  Future<void> save(String uid, PharmacyDraft draft) async {
    await _prefs.setString(nameKey(uid), draft.name);
    await _prefs.setString(locationKey(uid), draft.location);
  }

  @override
  Future<void> clear(String uid) async {
    await _prefs.remove(nameKey(uid));
    await _prefs.remove(locationKey(uid));
  }
}
