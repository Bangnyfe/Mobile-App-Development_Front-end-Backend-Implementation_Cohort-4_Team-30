import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sale.dart';
import '../../domain/entities/sales_day.dart';
import '../../domain/repositories/sales_repository.dart';

part 'sales_history_state.dart';

/// Listens to the sales stream and groups the sales by day for the page.
class SalesHistoryCubit extends Cubit<SalesHistoryState> {
  SalesHistoryCubit(this._repository) : super(const SalesHistoryLoading());

  final SalesRepository _repository;
  StreamSubscription<List<Sale>>? _subscription;

  static const loadFailedMessage = "Couldn't load your sales.";

  /// Starts (or restarts, from "Try again") listening for sales.
  void start() {
    _subscription?.cancel();
    emit(const SalesHistoryLoading());
    _subscription = _repository.watchSales().listen(
      (sales) => emit(
        SalesHistoryLoaded(
          days: groupSalesByDay(sales),
          isAtLimit: sales.length >= SalesRepository.defaultLimit,
        ),
      ),
      onError: (Object _) => emit(const SalesHistoryFailure(loadFailedMessage)),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
