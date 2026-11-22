import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/domain/entities/pos_product.dart';
import 'package:team30_app/features/pos/presentation/cubit/cart_cubit.dart';

final today = DateTime(2026, 9, 25, 14, 32);

const amoxicillin = PosProduct(
  id: 'amox',
  barcode: '6001234567895',
  name: 'Amoxicillin 500mg',
  sellingPrice: 2500,
);

const paracetamol = PosProduct(
  id: 'para',
  barcode: '6001007045678',
  name: 'Paracetamol 500mg',
  sellingPrice: 300,
);

final amoxBatch = PosBatch(
  id: 'b-ax2407',
  batchNumber: 'AX2407',
  expiryDate: DateTime(2026, 10, 14),
  quantity: 18,
);

final paraBatch = PosBatch(
  id: 'b-pc2506',
  batchNumber: 'PC2506',
  expiryDate: DateTime(2028, 3, 12),
  quantity: 60,
);

/// A cart with 2 × Amoxicillin (5,000) and 3 × Paracetamol (900):
/// 2 products, 5 units, RWF 5,900.
CartCubit seededCart() => CartCubit(clock: () => today)
  ..addItem(product: amoxicillin, batches: [amoxBatch], quantity: 2)
  ..addItem(product: paracetamol, batches: [paraBatch], quantity: 3);

/// A phone held sideways (780 × 360 dp), to catch overflow in landscape.
void useLandscapePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(2340, 1080);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
