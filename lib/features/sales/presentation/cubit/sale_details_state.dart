part of 'sale_details_cubit.dart';

sealed class SaleDetailsState extends Equatable {
  const SaleDetailsState();

  @override
  List<Object?> get props => [];
}

final class SaleDetailsLoading extends SaleDetailsState {
  const SaleDetailsLoading();
}

final class SaleDetailsLoaded extends SaleDetailsState {
  const SaleDetailsLoaded(this.sale);

  final Sale sale;

  @override
  List<Object?> get props => [sale];
}

/// No sale has this ID, e.g. an old link to a sale that was deleted.
final class SaleDetailsNotFound extends SaleDetailsState {
  const SaleDetailsNotFound();
}

final class SaleDetailsFailure extends SaleDetailsState {
  const SaleDetailsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
