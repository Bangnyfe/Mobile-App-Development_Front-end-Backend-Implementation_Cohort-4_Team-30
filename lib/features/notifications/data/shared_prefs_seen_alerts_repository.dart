import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/seen_alerts_repository.dart';

/// Saves the seen alert IDs on the device with SharedPreferences.
class SharedPrefsSeenAlertsRepository implements SeenAlertsRepository {
  SharedPrefsSeenAlertsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const seenIdsKey = 'notifications.seenAlertIds';

  @override
  Future<Set<String>> loadSeenIds() async =>
      (_prefs.getStringList(seenIdsKey) ?? const []).toSet();

  @override
  Future<void> saveSeenIds(Set<String> ids) =>
      _prefs.setStringList(seenIdsKey, ids.toList()..sort());
}
