import 'package:equatable/equatable.dart';

/// What a scanned barcode says about a pack.
///
/// A plain box barcode (EAN-13) only identifies the product. The GS1
/// DataMatrix printed on medicine packs also carries the batch number,
/// expiry date and serial number, so a scan can fill those in too.
class ScannedCode extends Equatable {
  const ScannedCode({
    required this.gtin,
    this.batchNumber,
    this.expiryDate,
    this.serialNumber,
  });

  /// The product's barcode, as stored in `products.barcode`: 13 digits for
  /// ordinary packs, so it matches the number printed under the bars.
  final String gtin;

  final String? batchNumber;

  /// The last day the pack may be used.
  final DateTime? expiryDate;

  final String? serialNumber;

  @override
  List<Object?> get props => [gtin, batchNumber, expiryDate, serialNumber];
}
