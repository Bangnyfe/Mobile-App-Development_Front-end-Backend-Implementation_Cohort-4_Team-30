import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/removable_product.dart';
import '../domain/entities/stock_removal.dart';
import '../domain/entities/removal_reason.dart';

/// Firestore field names used by Remove stock, exactly as in the ERD
/// : PRODUCTS, BATCHES and STOCK_REMOVALS.
abstract final class StockRemovalFields {
  // Collections under pharmacies/{pharmacyId}.
  static const products = 'products';
  static const batches = 'batches';
  static const stockRemovals = 'stock_removals';

  // products/{productId}
  static const name = 'name';
  static const barcode = 'barcode';
  static const form = 'form';
  static const packSize = 'packSize';

  // products/{productId}/batches/{batchId}
  static const batchNumber = 'batchNumber';
  static const expiryDate = 'expiryDate';
  static const quantity = 'quantity';
  static const costPrice = 'costPrice';

  // stock_removals/{removalId}
  static const productId = 'productId';
  static const batchId = 'batchId';
  static const productName = 'productName';
  static const reason = 'reason';
  static const note = 'note';
  static const costValue = 'costValue';
  static const removedBy = 'removedBy';
  static const removedByName = 'removedByName';
  static const createdAt = 'createdAt';
}

/// Reads a batch document, or returns null if it is missing its quantity
/// or expiry date (an incomplete record is skipped rather than shown).
RemovableBatch? batchFromFirestore(String id, Map<String, dynamic> data) {
  final quantity = (data[StockRemovalFields.quantity] as num?)?.toInt();
  final expiry = data[StockRemovalFields.expiryDate];
  if (quantity == null || expiry is! Timestamp) return null;
  final batchNumber = (data[StockRemovalFields.batchNumber] as String?)?.trim();
  return RemovableBatch(
    id: id,
    batchNumber: batchNumber == null || batchNumber.isEmpty ? id : batchNumber,
    expiryDate: expiry.toDate(),
    quantity: quantity,
    costPrice: (data[StockRemovalFields.costPrice] as num?)?.toInt() ?? 0,
  );
}

/// Builds a product from its document and its batches, earliest expiry
/// first. Its details line is the form and pack size, e.g.
/// "Tablets · strip of 10".
RemovableProduct productFromFirestore(
  String id,
  Map<String, dynamic> data,
  List<RemovableBatch> batches,
) {
  final details = [
    (data[StockRemovalFields.form] as String?)?.trim() ?? '',
    (data[StockRemovalFields.packSize] as String?)?.trim() ?? '',
  ].where((part) => part.isNotEmpty).join(' · ');
  final sorted = [...batches]
    ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

  return RemovableProduct(
    id: id,
    name: data[StockRemovalFields.name] as String? ?? 'Unnamed product',
    barcode: data[StockRemovalFields.barcode] as String? ?? '',
    details: details,
    batches: sorted,
  );
}

/// The `stock_removals` document for a removal. The product name, batch
/// number and remover's name are snapshots (as in the ERD), so the record
/// still reads correctly after a product is renamed.
Map<String, Object> removalToFirestore({
  required StockRemovalRequest request,
  required String productName,
  required String batchNumber,
  required int costValue,
  required String removedBy,
  required String removedByName,
}) => {
  StockRemovalFields.productId: request.productId,
  StockRemovalFields.batchId: request.batchId,
  StockRemovalFields.productName: productName,
  StockRemovalFields.batchNumber: batchNumber,
  StockRemovalFields.quantity: request.quantity,
  StockRemovalFields.reason: request.reason.name,
  StockRemovalFields.note: request.note.trim(),
  StockRemovalFields.costValue: costValue,
  StockRemovalFields.removedBy: removedBy,
  StockRemovalFields.removedByName: removedByName,
  StockRemovalFields.createdAt: FieldValue.serverTimestamp(),
};

/// Reads a `stock_removals` document, or returns null while its
/// `createdAt` server time has not been set.
StockRemoval? removalFromFirestore(String id, Map<String, dynamic> data) {
  final createdAt = data[StockRemovalFields.createdAt];
  if (createdAt is! Timestamp) return null;
  return StockRemoval(
    id: id,
    productId: data[StockRemovalFields.productId] as String? ?? '',
    productName: data[StockRemovalFields.productName] as String? ?? '',
    batchId: data[StockRemovalFields.batchId] as String? ?? '',
    batchNumber: data[StockRemovalFields.batchNumber] as String? ?? '',
    quantity: (data[StockRemovalFields.quantity] as num?)?.toInt() ?? 0,
    reason: RemovalReason.fromName(data[StockRemovalFields.reason] as String?),
    note: data[StockRemovalFields.note] as String? ?? '',
    costValue: (data[StockRemovalFields.costValue] as num?)?.toInt() ?? 0,
    removedBy: data[StockRemovalFields.removedBy] as String? ?? '',
    removedByName: data[StockRemovalFields.removedByName] as String? ?? '',
    createdAt: createdAt.toDate(),
  );
}

/// A Firestore error code as a message for the user.
String stockRemovalErrorMessage(String code) => switch (code) {
  'permission-denied' => 'You do not have permission to remove stock.',
  'unavailable' =>
    'No connection to the server. Check your internet and try again.',
  'aborted' => 'The stock changed while saving. Please try again.',
  'not-found' => 'This batch no longer exists.',
  _ => "Couldn't save the removal. Please try again.",
};
