import 'package:team30_app/features/inventory/domain/entities/batch.dart';
import 'package:team30_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:team30_app/features/inventory/domain/entities/product.dart';

/// "Today" in the inventory tests.
final inventoryToday = DateTime(2026, 11, 22, 9, 30);

Product testProduct({
  String id = 'p1',
  String name = 'Amoxicillin 500mg',
  String barcode = '6001007023454',
  int sellingPrice = 4500,
  int? reorderLevel,
}) => Product(
  id: id,
  barcode: barcode,
  name: name,
  form: 'Capsules',
  packSize: 'Box of 21',
  sellingPrice: sellingPrice,
  reorderLevel: reorderLevel,
);

/// A batch of [productId] expiring [expiresInDays] after [inventoryToday].
Batch testBatch({
  String id = 'b1',
  String productId = 'p1',
  String batchNumber = 'AMX-1',
  int expiresInDays = 200,
  int quantity = 50,
  int costPrice = 3000,
}) => Batch(
  id: id,
  pharmacyId: 'ph1',
  productId: productId,
  batchNumber: batchNumber,
  expiryDate: DateTime(
    inventoryToday.year,
    inventoryToday.month,
    inventoryToday.day + expiresInDays,
  ),
  quantity: quantity,
  costPrice: costPrice,
  receivedBy: 'u1',
  receivedByName: 'Aline Uwase',
);

InventoryItem testItem({
  String id = 'p1',
  String name = 'Amoxicillin 500mg',
  String barcode = '6001007023454',
  int? reorderLevel,
  List<Batch>? batches,
}) => InventoryItem(
  product: testProduct(
    id: id,
    name: name,
    barcode: barcode,
    reorderLevel: reorderLevel,
  ),
  batches: batches ?? [testBatch(productId: id)],
);
