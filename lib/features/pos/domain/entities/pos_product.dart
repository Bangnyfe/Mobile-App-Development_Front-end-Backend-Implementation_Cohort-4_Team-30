import 'package:equatable/equatable.dart';

class PosProduct extends Equatable {
  const PosProduct({
    required this.id,
    required this.barcode,
    required this.name,
    required this.sellingPrice,
  });

  final String id;
  final String barcode;
  final String name;

  /// Price per unit in whole RWF.
  final int sellingPrice;

  @override
  List<Object?> get props => [id, barcode, name, sellingPrice];
}
