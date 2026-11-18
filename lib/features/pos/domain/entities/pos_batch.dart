import 'package:equatable/equatable.dart';

/// A received lot of one product. Sales draw down a specific batch.
class PosBatch extends Equatable {
  const PosBatch({
    required this.id,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
  });

  final String id;
  final String batchNumber;
  final DateTime expiryDate;
  final int quantity;

  /// A batch is expired once its expiry day is before [today] (date only).
  bool isExpiredOn(DateTime today) {
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final day = DateTime(today.year, today.month, today.day);
    return expiry.isBefore(day);
  }

  /// Sellable means in stock and not expired.
  bool isSellableOn(DateTime today) => quantity > 0 && !isExpiredOn(today);

  @override
  List<Object?> get props => [id, batchNumber, expiryDate, quantity];
}
