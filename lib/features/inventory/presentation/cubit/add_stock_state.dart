part of 'add_stock_cubit.dart';

/// The Add stock flow: scan → (register the product if it's new) → batch
/// details → done.
sealed class AddStockState extends Equatable {
  const AddStockState();

  @override
  List<Object?> get props => [];
}

/// Waiting for the user to scan a pack.
final class AddStockScan extends AddStockState {
  const AddStockScan();
}

/// Finding the scanned barcode (or the product passed in).
final class AddStockLookingUp extends AddStockState {
  const AddStockLookingUp();
}

/// No product has this barcode yet, so it must be registered first.
final class AddStockNotRegistered extends AddStockState {
  const AddStockNotRegistered(this.code);

  final ScannedCode code;

  @override
  List<Object?> get props => [code];
}

/// Entering the batch details. [code] pre-fills the batch number and
/// expiry date when a DataMatrix was scanned.
final class AddStockDetails extends AddStockState {
  const AddStockDetails({
    required this.product,
    this.code,
    this.saving = false,
    this.errorMessage,
  });

  final Product product;
  final ScannedCode? code;
  final bool saving;

  /// Why the last save failed.
  final String? errorMessage;

  AddStockDetails copyWith({bool? saving, String? errorMessage}) =>
      AddStockDetails(
        product: product,
        code: code,
        saving: saving ?? this.saving,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [product, code, saving, errorMessage];
}

final class AddStockDone extends AddStockState {
  const AddStockDone({required this.product, required this.batch});

  final Product product;
  final Batch batch;

  @override
  List<Object?> get props => [product, batch];
}

/// The lookup failed (offline, or the product was deleted).
final class AddStockFailure extends AddStockState {
  const AddStockFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
