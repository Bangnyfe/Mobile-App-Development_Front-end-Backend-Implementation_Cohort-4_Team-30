import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/pharmacy_draft.dart';
import '../domain/repositories/pharmacy_draft_repository.dart';

/// Saves pharmacy drafts on the device with SharedPreferences.
class SharedPrefsPharmacyDraftRepository implements PharmacyDraftRepository {
  SharedPrefsPharmacyDraftRepository(this._prefs);

  final SharedPreferences _prefs;

  static String nameKey(String uid) => 'pharmacyDraft.$uid.name';
  static String districtKey(String uid) => 'pharmacyDraft.$uid.district';
  static String cityKey(String uid) => 'pharmacyDraft.$uid.city';

  @override
  Future<PharmacyDraft?> load(String uid) async {
    final name = _prefs.getString(nameKey(uid));
    if (name == null) return null;
    return PharmacyDraft(
      name: name,
      district: _prefs.getString(districtKey(uid)) ?? '',
      city: _prefs.getString(cityKey(uid)) ?? '',
    );
  }

  @override
  Future<void> save(String uid, PharmacyDraft draft) async {
    await _prefs.setString(nameKey(uid), draft.name);
    await _prefs.setString(districtKey(uid), draft.district);
    await _prefs.setString(cityKey(uid), draft.city);
  }

  @override
  Future<void> clear(String uid) async {
    await _prefs.remove(nameKey(uid));
    await _prefs.remove(districtKey(uid));
    await _prefs.remove(cityKey(uid));
  }
}
