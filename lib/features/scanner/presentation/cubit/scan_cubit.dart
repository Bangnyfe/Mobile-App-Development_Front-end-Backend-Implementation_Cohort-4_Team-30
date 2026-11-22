import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../pos/domain/entities/pos_batch.dart';
import '../../domain/entities/found_product.dart';
import '../../domain/entities/scanned_code.dart';
import '../../domain/repositories/product_lookup_repository.dart';

part 'scan_state.dart';

/// Looks a scanned barcode up among the pharmacy's products.
class ScanCubit extends Cubit<ScanState> {
  ScanCubit(this._repository) : super(const ScanIdle());

  final ProductLookupRepository _repository;

  static const lookupFailedMessage =
      "Couldn't look the product up. Check your connection and try again.";

  Future<void> lookUp(ScannedCode code) async {
    emit(ScanLookingUp(code));
    final FoundProduct? found;
    try {
      found = await _repository.findByBarcode(code.gtin);
    } catch (_) {
      if (_isCurrent(code)) emit(ScanFailure(code, lookupFailedMessage));
      return;
    }
    // A newer scan may have started while this one was loading.
    if (!_isCurrent(code)) return;
    emit(found == null ? ScanNotFound(code) : ScanFound(code, found));
  }

  /// Looks the last code up again, after a failure.
  Future<void> retry() async {
    if (state case ScanFailure(:final code)) await lookUp(code);
  }

  void reset() => emit(const ScanIdle());

  bool _isCurrent(ScannedCode code) =>
      !isClosed &&
      state is ScanLookingUp &&
      (state as ScanLookingUp).code == code;
}
