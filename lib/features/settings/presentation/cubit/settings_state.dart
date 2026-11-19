part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.settings = const AppSettings(),
    this.isLoaded = false,
    this.error,
    this.errorCount = 0,
  });

  /// Defaults until [isLoaded], so screens can show values straight away.
  final AppSettings settings;
  final bool isLoaded;
  final String? error;

  /// Goes up by one on every error, so the same message twice in a row is
  /// still emitted (equal states aren't) and its SnackBar shows again.
  final int errorCount;

  SettingsState withSettings(AppSettings settings) =>
      SettingsState(settings: settings, isLoaded: true, errorCount: errorCount);

  SettingsState withError(String message) => SettingsState(
    settings: settings,
    isLoaded: isLoaded,
    error: message,
    errorCount: errorCount + 1,
  );

  @override
  List<Object?> get props => [settings, isLoaded, error, errorCount];
}
