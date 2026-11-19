import '../entities/app_settings.dart';

/// Reads and saves the user's [AppSettings].
abstract interface class SettingsRepository {
  /// The saved settings, with defaults for anything never set.
  Future<AppSettings> load();

  Future<void> saveLowStockThreshold(int value);

  Future<void> saveExpiryAlertDays(int value);

  Future<void> savePushNotificationsEnabled(bool value);
}
