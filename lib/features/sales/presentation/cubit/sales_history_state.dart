part of 'sales_history_cubit.dart';

sealed class SalesHistoryState extends Equatable {
  const SalesHistoryState();

  @override
  List<Object?> get props => [];
}

final class SalesHistoryLoading extends SalesHistoryState {
  const SalesHistoryLoading();
}

final class SalesHistoryLoaded extends SalesHistoryState {
  const SalesHistoryLoaded({required this.days, this.isAtLimit = false});

  /// Newest day first. Empty when there are no sales yet.
  final List<SalesDay> days;

  /// True when the history reached the repository's limit, so older sales
  /// aren't shown.
  final bool isAtLimit;

  @override
  List<Object?> get props => [days, isAtLimit];
}

final class SalesHistoryFailure extends SalesHistoryState {
  const SalesHistoryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
