import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../stock_removal/domain/entities/removable_product.dart';
import '../../../stock_removal/domain/entities/removal_reason.dart';
import '../../../stock_removal/domain/entities/stock_removal.dart';
import '../../../stock_removal/domain/repositories/stock_removal_repository.dart';
import '../../domain/report_period.dart';
import '../../domain/stock_report.dart';

part 'stock_reports_state.dart';

/// Loads the stock and the last 12 months of removals for the Inventory
/// report and the Expiry and waste report. Both read the same data that
/// Remove stock writes, so a removal shows up the next time either opens.
class StockReportsCubit extends Cubit<StockReportsState> {
  StockReportsCubit(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(StockReportsState());

  final StockRemovalRepository _repository;
  final DateTime Function() _clock;

  static const loadFailedMessage =
      "Couldn't load the report. Check your connection and try again.";

  Future<void> load() async {
    final today = _clock();
    emit(
      state.copyWith(
        status: StockReportsStatus.loading,
        today: today,
        message: () => null,
      ),
    );
    try {
      final products = await _repository.loadProducts();
      final removals = await _repository.loadRemovals(
        since: ReportPeriod.year.startOn(today),
      );
      emit(
        state.copyWith(
          status: StockReportsStatus.ready,
          products: products,
          removals: removals,
        ),
      );
    } on StockRemovalFailure catch (failure) {
      emit(
        state.copyWith(
          status: StockReportsStatus.failure,
          message: () => failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: StockReportsStatus.failure,
          message: () => loadFailedMessage,
        ),
      );
    }
  }

  void selectPeriod(ReportPeriod period) =>
      emit(state.copyWith(period: period));
}
