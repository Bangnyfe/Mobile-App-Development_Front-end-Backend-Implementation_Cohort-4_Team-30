import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../settings/domain/entities/app_settings.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';

part 'dashboard_state.dart';

/// Listens to the dashboard summary stream and exposes it as UI state.
///
/// Follows the alert settings: when the low-stock threshold or expiry alert
/// days change, the summary is worked out again with the new values.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(
    this._repository, {
    AppSettings initialSettings = const AppSettings(),
    Stream<AppSettings>? settingsChanges,
  }) : _settings = initialSettings,
       super(const DashboardLoading()) {
    _settingsSubscription = settingsChanges?.listen(_onSettings);
  }

  final DashboardRepository _repository;
  AppSettings _settings;
  StreamSubscription<DashboardSummary>? _subscription;
  StreamSubscription<AppSettings>? _settingsSubscription;

  static const loadFailedMessage = 'Could not load the dashboard. Try again.';

  /// Starts (or restarts, e.g. from a "Try again" button) listening.
  void start() {
    emit(const DashboardLoading());
    _listen();
  }

  void _onSettings(AppSettings settings) {
    final changed =
        settings.lowStockThreshold != _settings.lowStockThreshold ||
        settings.expiryAlertDays != _settings.expiryAlertDays;
    _settings = settings;
    // Before start(), the new settings are simply used when it's called.
    // After, keep the current numbers on screen until the new ones arrive.
    if (changed && _subscription != null) _listen();
  }

  void _listen() {
    // Not awaited: cancelling stops events straight away, and the future
    // of a stream that already failed may never complete.
    unawaited(_subscription?.cancel());
    _subscription = _repository
        .watchSummary(_settings)
        .listen(
          (summary) => emit(DashboardLoaded(summary)),
          onError: (Object _) =>
              emit(const DashboardFailure(loadFailedMessage)),
        );
  }

  @override
  Future<void> close() async {
    unawaited(_subscription?.cancel());
    await _settingsSubscription?.cancel();
    return super.close();
  }
}
