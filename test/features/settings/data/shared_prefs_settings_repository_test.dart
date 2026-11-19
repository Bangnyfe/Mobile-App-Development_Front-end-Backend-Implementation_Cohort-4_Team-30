import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:team30_app/features/settings/domain/entities/app_settings.dart';

void main() {
  Future<SharedPrefsSettingsRepository> repositoryWith(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPrefsSettingsRepository(await SharedPreferences.getInstance());
  }

  test('uses the defaults when nothing has been saved', () async {
    final repository = await repositoryWith({});

    expect(
      await repository.load(),
      const AppSettings(
        lowStockThreshold: 20,
        expiryAlertDays: 90,
        pushNotificationsEnabled: true,
      ),
    );
  });

  test('loads what was saved', () async {
    final repository = await repositoryWith({});

    await repository.saveLowStockThreshold(35);
    await repository.saveExpiryAlertDays(30);
    await repository.savePushNotificationsEnabled(false);

    expect(
      await repository.load(),
      const AppSettings(
        lowStockThreshold: 35,
        expiryAlertDays: 30,
        pushNotificationsEnabled: false,
      ),
    );
  });

  test('falls back to the defaults for out-of-range values', () async {
    final repository = await repositoryWith({
      SharedPrefsSettingsRepository.lowStockThresholdKey: 0,
      SharedPrefsSettingsRepository.expiryAlertDaysKey: 400,
    });

    final settings = await repository.load();

    expect(settings.lowStockThreshold, AppSettings.defaultLowStockThreshold);
    expect(settings.expiryAlertDays, AppSettings.defaultExpiryAlertDays);
  });
}
