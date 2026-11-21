import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../settings/domain/entities/app_settings.dart';
import '../../domain/build_stock_alerts.dart';
import '../../domain/entities/alert_product.dart';
import '../../domain/entities/stock_alert.dart';
import '../../domain/repositories/seen_alerts_repository.dart';
import '../../domain/repositories/stock_alerts_repository.dart';

part 'notifications_state.dart';

/// Works out the stock alerts and which of them are new.
///
/// Provided once for the whole app, so the dashboard bell and the
/// Notifications page always agree. The alerts are worked out again
/// whenever the stock or the alert settings change.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required this._stockRepository,
    required this._seenRepository,
    required AppSettings initialSettings,
    required Stream<AppSettings> settingsChanges,
    DateTime Function()? clock,
  }) : _settings = initialSettings,
       _clock = clock ?? DateTime.now,
       super(const NotificationsLoading()) {
    // Listened to straight away, so a change (e.g. the saved settings
    // finishing loading) can't be missed while start() is still waiting.
    _settingsSubscription = settingsChanges.listen((settings) {
      _settings = settings;
      _emitAlerts();
    });
  }

  final StockAlertsRepository _stockRepository;
  final SeenAlertsRepository _seenRepository;
  final DateTime Function() _clock;

  AppSettings _settings;
  List<AlertProduct>? _products;
  Set<String> _seenIds = const {};

  StreamSubscription<List<AlertProduct>>? _stockSubscription;
  late final StreamSubscription<AppSettings> _settingsSubscription;

  static const loadFailedMessage = "Couldn't load your alerts.";

  /// Starts (or restarts, from "Try again") watching the stock.
  Future<void> start() async {
    // Not awaited: cancelling stops events straight away, and the future
    // of a stream that already failed may never complete.
    unawaited(_stockSubscription?.cancel());
    _stockSubscription = null;
    _products = null;
    emit(const NotificationsLoading());

    try {
      _seenIds = await _seenRepository.loadSeenIds();
    } catch (_) {
      // Not knowing what was seen only means every alert shows as new.
      _seenIds = const {};
    }
    if (isClosed) return;

    _stockSubscription = _stockRepository.watchStock().listen(
      (products) {
        _products = products;
        _emitAlerts();
      },
      onError: (Object _) {
        _products = null;
        emit(const NotificationsFailure(loadFailedMessage));
      },
    );
  }

  /// Marks every current alert as seen, which clears the bell's badge.
  ///
  /// Only the current alerts' IDs are saved, so alerts that no longer
  /// exist are forgotten.
  Future<void> markAllSeen() async {
    final current = state;
    if (isClosed || current is! NotificationsLoaded) return;
    if (current.newCount == 0) return;

    _seenIds = {for (final alert in current.alerts) alert.id};
    emit(NotificationsLoaded(alerts: current.alerts, seenIds: _seenIds));
    try {
      await _seenRepository.saveSeenIds(_seenIds);
    } catch (_) {
      // Still cleared for now; the alerts just show as new again after a
      // restart.
    }
  }

  void _emitAlerts() {
    final products = _products;
    if (products == null || isClosed) return;

    emit(
      NotificationsLoaded(
        alerts: buildStockAlerts(
          products,
          today: _clock(),
          lowStockThreshold: _settings.lowStockThreshold,
          expiryAlertDays: _settings.expiryAlertDays,
        ),
        seenIds: _seenIds,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _stockSubscription?.cancel();
    await _settingsSubscription.cancel();
    return super.close();
  }
}
