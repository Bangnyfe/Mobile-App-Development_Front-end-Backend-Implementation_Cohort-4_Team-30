import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/settings/domain/entities/app_settings.dart';
import 'package:team30_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:team30_app/features/settings/presentation/cubit/settings_cubit.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository([this.saved = const AppSettings()]);

  AppSettings saved;
  bool failLoad = false;
  bool failSave = false;

  @override
  Future<AppSettings> load() async {
    if (failLoad) throw Exception('load failed');
    return saved;
  }

  void _check() {
    if (failSave) throw Exception('save failed');
  }

  @override
  Future<void> saveLowStockThreshold(int value) async {
    _check();
    saved = saved.copyWith(lowStockThreshold: value);
  }

  @override
  Future<void> saveExpiryAlertDays(int value) async {
    _check();
    saved = saved.copyWith(expiryAlertDays: value);
  }

  @override
  Future<void> savePushNotificationsEnabled(bool value) async {
    _check();
    saved = saved.copyWith(pushNotificationsEnabled: value);
  }
}

void main() {
  const custom = AppSettings(
    lowStockThreshold: 10,
    expiryAlertDays: 60,
    pushNotificationsEnabled: false,
  );

  test('starts with the defaults before loading', () {
    final cubit = SettingsCubit(_FakeSettingsRepository());

    expect(cubit.state.settings, const AppSettings());
    expect(cubit.state.isLoaded, isFalse);
  });

  blocTest<SettingsCubit, SettingsState>(
    'load emits the saved settings',
    build: () => SettingsCubit(_FakeSettingsRepository(custom)),
    act: (cubit) => cubit.load(),
    expect: () => [const SettingsState(settings: custom, isLoaded: true)],
  );

  blocTest<SettingsCubit, SettingsState>(
    'keeps the defaults and reports an error when loading fails',
    build: () => SettingsCubit(_FakeSettingsRepository()..failLoad = true),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<SettingsState>()
          .having((s) => s.settings, 'settings', const AppSettings())
          .having((s) => s.error, 'error', isNotNull),
    ],
  );

  group('low-stock threshold', () {
    late _FakeSettingsRepository repository;

    blocTest<SettingsCubit, SettingsState>(
      'saves a valid value and shows it',
      build: () => SettingsCubit(repository = _FakeSettingsRepository()),
      act: (cubit) => cubit.updateLowStockThreshold(35),
      expect: () => [
        const SettingsState(
          settings: AppSettings(lowStockThreshold: 35),
          isLoaded: true,
        ),
      ],
      verify: (_) => expect(repository.saved.lowStockThreshold, 35),
    );

    for (final invalid in [0, -5, 1001]) {
      test('rejects $invalid without saving', () async {
        final repository = _FakeSettingsRepository();
        final cubit = SettingsCubit(repository);

        expect(await cubit.updateLowStockThreshold(invalid), isFalse);
        expect(cubit.state.error, 'Enter a number from 1 to 1000.');
        expect(repository.saved.lowStockThreshold, 20);
      });
    }
  });

  group('expiry alert period', () {
    test('saves a valid value', () async {
      final repository = _FakeSettingsRepository();
      final cubit = SettingsCubit(repository);

      expect(await cubit.updateExpiryAlertDays(30), isTrue);
      expect(cubit.state.settings.expiryAlertDays, 30);
      expect(repository.saved.expiryAlertDays, 30);
    });

    for (final invalid in [0, 366]) {
      test('rejects $invalid without saving', () async {
        final repository = _FakeSettingsRepository();
        final cubit = SettingsCubit(repository);

        expect(await cubit.updateExpiryAlertDays(invalid), isFalse);
        expect(cubit.state.error, 'Enter a number of days from 1 to 365.');
        expect(repository.saved.expiryAlertDays, 90);
      });
    }
  });

  test('turns push notifications off and on', () async {
    final repository = _FakeSettingsRepository();
    final cubit = SettingsCubit(repository);

    await cubit.setPushNotificationsEnabled(false);
    expect(cubit.state.settings.pushNotificationsEnabled, isFalse);
    expect(repository.saved.pushNotificationsEnabled, isFalse);

    await cubit.setPushNotificationsEnabled(true);
    expect(cubit.state.settings.pushNotificationsEnabled, isTrue);
  });

  test('keeps the old value when saving fails', () async {
    final cubit = SettingsCubit(_FakeSettingsRepository()..failSave = true);

    expect(await cubit.updateLowStockThreshold(35), isFalse);
    expect(cubit.state.settings.lowStockThreshold, 20);
    expect(cubit.state.error, SettingsCubit.saveFailedMessage);
  });

  blocTest<SettingsCubit, SettingsState>(
    'emits the same error again when it happens twice in a row',
    build: () => SettingsCubit(_FakeSettingsRepository()),
    act: (cubit) async {
      await cubit.updateLowStockThreshold(0);
      await cubit.updateLowStockThreshold(0);
    },
    expect: () => [
      isA<SettingsState>().having((s) => s.errorCount, 'errorCount', 1),
      isA<SettingsState>().having((s) => s.errorCount, 'errorCount', 2),
    ],
  );
}
