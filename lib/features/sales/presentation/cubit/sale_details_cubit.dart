import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sale.dart';
import '../../domain/repositories/sales_repository.dart';

part 'sale_details_state.dart';

/// Loads one sale for the Sale details page.
class SaleDetailsCubit extends Cubit<SaleDetailsState> {
  SaleDetailsCubit(this._repository, this.saleId)
    : super(const SaleDetailsLoading());

  final SalesRepository _repository;
  final String saleId;

  static const loadFailedMessage = "Couldn't load this sale.";

  /// Loads (or reloads, from "Try again") the sale.
  Future<void> load() async {
    emit(const SaleDetailsLoading());
    try {
      final sale = await _repository.getSale(saleId);
      emit(
        sale == null ? const SaleDetailsNotFound() : SaleDetailsLoaded(sale),
      );
    } catch (_) {
      emit(const SaleDetailsFailure(loadFailedMessage));
    }
  }
}
