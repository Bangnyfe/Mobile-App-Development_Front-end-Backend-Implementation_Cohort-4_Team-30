part of 'notifications_cubit.dart';

sealed class NotificationsState extends Equatable {
  const NotificationsState();

  /// Alerts the user hasn't seen yet, for the bell's badge. Zero while
  /// loading or after an error, so the badge never shows a wrong number.
  int get newCount => 0;

  @override
  List<Object?> get props => [];
}

final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

final class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded({required this.alerts, this.seenIds = const {}});

  /// Most urgent first: expired, then expiring soon, then low stock. Empty
  /// when everything is in order.
  final List<StockAlert> alerts;

  /// IDs of the alerts the user has already seen.
  final Set<String> seenIds;

  bool isNew(StockAlert alert) => !seenIds.contains(alert.id);

  @override
  int get newCount => alerts.where(isNew).length;

  @override
  List<Object?> get props => [alerts, seenIds];
}

final class NotificationsFailure extends NotificationsState {
  const NotificationsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
