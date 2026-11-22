part of 'scan_cubit.dart';

/// Where a barcode lookup is.
sealed class ScanState extends Equatable {
  const ScanState();

  @override
  List<Object?> get props => [];
}

/// Nothing scanned yet.
final class ScanIdle extends ScanState {
  const ScanIdle();
}

/// Looking the scanned [code] up.
final class ScanLookingUp extends ScanState {
  const ScanLookingUp(this.code);

  final ScannedCode code;

  @override
  List<Object?> get props => [code];
}

/// The pharmacy stocks the scanned product.
final class ScanFound extends ScanState {
  const ScanFound(this.code, this.found);

  final ScannedCode code;
  final FoundProduct found;

  /// The batch a GS1 DataMatrix named, if the pharmacy has it.
  PosBatch? get scannedBatch {
    final number = code.batchNumber;
    return number == null ? null : found.batchNumbered(number);
  }

  @override
  List<Object?> get props => [code, found];
}

/// No product of this pharmacy has the scanned barcode.
final class ScanNotFound extends ScanState {
  const ScanNotFound(this.code);

  final ScannedCode code;

  @override
  List<Object?> get props => [code];
}

/// The lookup failed, for example offline.
final class ScanFailure extends ScanState {
  const ScanFailure(this.code, this.message);

  final ScannedCode code;
  final String message;

  @override
  List<Object?> get props => [code, message];
}
