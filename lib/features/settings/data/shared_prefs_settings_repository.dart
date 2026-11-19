import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

/// Saves settings on the device with SharedPreferences.
class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const lowStockThresholdKey = 'settings.lowStockThreshold';
  static const expiryAlertDaysKey = 'settings.expiryAlertDays';
  static const pushNotificationsKey = 'settings.pushNotificationsEnabled';

  @override
  Future<AppSettings> load() async {
    final threshold = _prefs.getInt(lowStockThresholdKey);
    final expiryDays = _prefs.getInt(expiryAlertDaysKey);

    // A value outside the allowed range (e.g. saved by an older version)
    // falls back to the default rather than breaking the alerts.
    return AppSettings(
      lowStockThreshold:
          threshold != null && AppSettings.isValidLowStockThreshold(threshold)
          ? threshold
          : AppSettings.defaultLowStockThreshold,
      expiryAlertDays:
          expiryDays != null && AppSettings.isValidExpiryAlertDays(expiryDays)
          ? expiryDays
          : AppSettings.defaultExpiryAlertDays,
      pushNotificationsEnabled: _prefs.getBool(pushNotificationsKey) ?? true,
    );
  }

  @override
  Future<void> saveLowStockThreshold(int value) =>
      _prefs.setInt(lowStockThresholdKey, value);

  @override
  Future<void> saveExpiryAlertDays(int value) =>
      _prefs.setInt(expiryAlertDaysKey, value);

  @override
  Future<void> savePushNotificationsEnabled(bool value) =>
      _prefs.setBool(pushNotificationsKey, value);
}
