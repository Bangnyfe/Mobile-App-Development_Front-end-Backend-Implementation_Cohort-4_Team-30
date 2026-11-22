import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../scanner/domain/entities/scanned_code.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/product.dart';
import '../../domain/inventory_failure.dart';
import '../../domain/repositories/inventory_repository.dart';

part 'add_stock_state.dart';

/// Receives a new batch of a product.
///
/// Starts from a scan, or from a product chosen on Product details. A
/// barcode nobody has registered leads to Register product first.
class AddStockCubit extends Cubit<AddStockState> {
  /// [receivedBy] and [receivedByName] are the signed-in user's, saved on
  /// the batch.
  AddStockCubit(
    this._repository, {
    required this.receivedBy,
    required this.receivedByName,
  }) : super(const AddStockScan());

  final InventoryRepository _repository;
  final String receivedBy;
  final String receivedByName;

  /// Skips the scan when Add stock is opened from a product.
  Future<void> start({String? productId}) async {
    if (productId == null) return emit(const AddStockScan());
    emit(const AddStockLookingUp());
    try {
      final item = await _repository.watchItem(productId).first;
      emit(
        item == null
            ? const AddStockFailure(InventoryFailure.notFound)
            : AddStockDetails(product: item.product),
      );
    } catch (error) {
      emit(AddStockFailure(_messageFor(error)));
    }
  }

  Future<void> scanned(ScannedCode code) async {
    emit(const AddStockLookingUp());
    try {
      final product = await _repository.findByBarcode(code.gtin);
      emit(
        product == null
            ? AddStockNotRegistered(code)
            : AddStockDetails(product: product, code: code),
      );
    } catch (error) {
      emit(AddStockFailure(_messageFor(error)));
    }
  }

  /// The product was just registered for the scanned barcode; carry on
  /// with the same scan, so a DataMatrix still fills in the batch.
  void productRegistered(Product product) {
    final current = state;
    emit(
      AddStockDetails(
        product: product,
        code: current is AddStockNotRegistered ? current.code : null,
      ),
    );
  }

  Future<void> save({
    required String batchNumber,
    required DateTime expiryDate,
    required int quantity,
    required int costPrice,
  }) async {
    final current = state;
    if (current is! AddStockDetails || current.saving) return;
    emit(current.copyWith(saving: true));
    try {
      final batch = await _repository.addBatch(
        Batch(
          id: '',
          // Set by the repository to the signed-in pharmacy.
          pharmacyId: '',
          productId: current.product.id,
          batchNumber: batchNumber.trim(),
          expiryDate: DateTime(
            expiryDate.year,
            expiryDate.month,
            expiryDate.day,
          ),
          quantity: quantity,
          costPrice: costPrice,
          receivedBy: receivedBy,
          receivedByName: receivedByName,
        ),
      );
      emit(AddStockDone(product: current.product, batch: batch));
    } catch (error) {
      emit(current.copyWith(saving: false, errorMessage: _messageFor(error)));
    }
  }

  void scanAnother() => emit(const AddStockScan());

  static String _messageFor(Object error) =>
      error is InventoryFailure ? error.message : InventoryFailure.generic;
}
