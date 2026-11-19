import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

part 'settings_state.dart';

/// Holds the user's settings for the whole app.
///
/// Provided once above the router, so the dashboard, inventory and
/// notifications can all read the same threshold and alert period, e.g.
/// `context.select((SettingsCubit c) => c.state.settings.expiryAlertDays)`.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;

  static const saveFailedMessage = "Couldn't save the setting. Try again.";

  Future<void> load() async {
    try {
      emit(state.withSettings(await _repository.load()));
    } catch (_) {
      // Keep the defaults so the app still works.
      emit(state.withError("Couldn't load your settings. Using defaults."));
    }
  }

  /// Returns true when saved, so a subpage knows it can close.
  Future<bool> updateLowStockThreshold(int value) async {
    if (!AppSettings.isValidLowStockThreshold(value)) {
      emit(
        state.withError(
          'Enter a number from ${AppSettings.minLowStockThreshold} '
          'to ${AppSettings.maxLowStockThreshold}.',
        ),
      );
      return false;
    }
    return _save(
      () => _repository.saveLowStockThreshold(value),
      state.settings.copyWith(lowStockThreshold: value),
    );
  }

  /// Returns true when saved, so a subpage knows it can close.
  Future<bool> updateExpiryAlertDays(int value) async {
    if (!AppSettings.isValidExpiryAlertDays(value)) {
      emit(
        state.withError(
          'Enter a number of days from ${AppSettings.minExpiryAlertDays} '
          'to ${AppSettings.maxExpiryAlertDays}.',
        ),
      );
      return false;
    }
    return _save(
      () => _repository.saveExpiryAlertDays(value),
      state.settings.copyWith(expiryAlertDays: value),
    );
  }

  Future<bool> setPushNotificationsEnabled(bool value) => _save(
    () => _repository.savePushNotificationsEnabled(value),
    state.settings.copyWith(pushNotificationsEnabled: value),
  );

  /// Saves first and only then shows the new value, so the screen never
  /// shows a setting that wasn't actually stored.
  Future<bool> _save(Future<void> Function() save, AppSettings updated) async {
    try {
      await save();
      emit(state.withSettings(updated));
      return true;
    } catch (_) {
      emit(state.withError(saveFailedMessage));
      return false;
    }
  }
}
