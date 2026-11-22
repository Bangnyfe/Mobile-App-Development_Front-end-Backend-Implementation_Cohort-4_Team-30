import 'dart:async';

import '../domain/entities/batch.dart';
import '../domain/entities/category.dart';
import '../domain/entities/inventory_item.dart';
import '../domain/entities/product.dart';
import '../domain/inventory_failure.dart';
import '../domain/repositories/inventory_repository.dart';

/// Sample inventory kept in memory, for widget tests; the app uses
/// Firestore. Uses the same products, barcodes and batch numbers as the
/// scanner and Remove stock samples.
///
/// Expiry dates are relative to [clock], so there is always an expired and
/// an expiring batch to see.
class FakeInventoryRepository implements InventoryRepository {
  FakeInventoryRepository({
    DateTime Function()? clock,
    List<Product>? products,
    List<Batch>? batches,
    List<ProductCategory>? categories,
  }) {
    final today = _dateOnly((clock ?? DateTime.now)());
    // Copied, so the samples (and lists passed in) can be changed here.
    _products = [...products ?? sampleProducts()];
    _batches = [...batches ?? sampleBatches(today)];
    _categories = [...categories ?? sampleCategories()];
  }

  late final List<Product> _products;
  late final List<Batch> _batches;
  late final List<ProductCategory> _categories;
  final _changes = StreamController<void>.broadcast();
  var _nextId = 1;

  /// Makes every call fail, to show the error states.
  bool fail = false;

  /// Makes owner-only calls fail, as the rules do for a pharmacist.
  bool ownerOnly = false;

  List<Batch> get batches => List.unmodifiable(_batches);
  List<Product> get products => List.unmodifiable(_products);
  List<ProductCategory> get categories => List.unmodifiable(_categories);

  static const _offline = InventoryFailure(InventoryFailure.generic);

  @override
  Stream<List<InventoryItem>> watchInventory() => _watch(_items);

  @override
  Stream<InventoryItem?> watchItem(String productId) => _watch(() {
    for (final item in _items()) {
      if (item.product.id == productId) return item;
    }
    return null;
  });

  @override
  Stream<List<ProductCategory>> watchCategories() =>
      _watch(() => [..._categories]..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Future<Product?> findByBarcode(String barcode) async {
    _check();
    for (final product in _products) {
      if (product.barcode == barcode.trim()) return product;
    }
    return null;
  }

  @override
  Future<Product> registerProduct(Product product) async {
    _check();
    final barcode = product.barcode.trim();
    if (barcode.isNotEmpty && await findByBarcode(barcode) != null) {
      throw const InventoryFailure(InventoryFailure.duplicateBarcode);
    }
    final saved = product.copyWith(id: 'p-new-${_nextId++}', barcode: barcode);
    _products.add(saved);
    _changed();
    return saved;
  }

  @override
  Future<ProductCategory> addCategory(String name) async {
    _check();
    final saved = ProductCategory(id: 'c-new-${_nextId++}', name: name.trim());
    _categories.add(saved);
    _changed();
    return saved;
  }

  @override
  Future<Batch> addBatch(Batch batch) async {
    _check();
    final saved = batch.copyWith(id: 'b-new-${_nextId++}');
    _batches.add(saved);
    _changed();
    return saved;
  }

  @override
  Future<void> updatePricing(
    String productId, {
    required int sellingPrice,
    int? reorderLevel,
  }) async {
    _check(ownerAction: true);
    final index = _products.indexWhere((product) => product.id == productId);
    if (index < 0) throw const InventoryFailure(InventoryFailure.notFound);
    _products[index] = _products[index].copyWith(
      sellingPrice: sellingPrice,
      reorderLevel: reorderLevel,
      clearReorderLevel: reorderLevel == null,
    );
    _changed();
  }

  @override
  Future<void> deleteProduct(String productId) async {
    _check(ownerAction: true);
    _products.removeWhere((product) => product.id == productId);
    _batches.removeWhere((batch) => batch.productId == productId);
    _changed();
  }

  @override
  Future<void> deleteBatch({
    required String productId,
    required String batchId,
  }) async {
    _check(ownerAction: true);
    _batches.removeWhere((batch) => batch.id == batchId);
    _changed();
  }

  void _check({bool ownerAction = false}) {
    if (fail) throw _offline;
    if (ownerAction && ownerOnly) {
      throw const InventoryFailure(InventoryFailure.ownerOnly);
    }
  }

  void _changed() => _changes.add(null);

  /// The current value, then a new one after every change.
  Stream<T> _watch<T>(T Function() read) async* {
    if (fail) throw _offline;
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  List<InventoryItem> _items() {
    final products = [..._products]..sort((a, b) => a.name.compareTo(b.name));
    final batches = [..._batches]
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return [
      for (final product in products)
        InventoryItem(
          product: product,
          batches: [
            for (final batch in batches)
              if (batch.productId == product.id) batch,
          ],
        ),
    ];
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static List<ProductCategory> sampleCategories() => const [
    ProductCategory(id: 'c-antibiotics', name: 'Antibiotics'),
    ProductCategory(id: 'c-pain', name: 'Pain relief'),
    ProductCategory(id: 'c-cough', name: 'Cough & cold'),
    ProductCategory(id: 'c-digestive', name: 'Digestive'),
  ];

  static List<Product> sampleProducts() => const [
    Product(
      id: 'p-metronidazole',
      barcode: '6001007012342',
      name: 'Metronidazole 400mg',
      form: 'Tablets',
      packSize: 'Strip of 10',
      categoryId: 'c-antibiotics',
      sellingPrice: 1500,
    ),
    Product(
      id: 'amoxicillin-500',
      barcode: '6001007023454',
      name: 'Amoxicillin 500mg',
      form: 'Capsules',
      packSize: 'Box of 21',
      categoryId: 'c-antibiotics',
      sellingPrice: 4500,
      reorderLevel: 30,
    ),
    Product(
      id: 'cough-syrup-100',
      barcode: '6001007056780',
      name: 'Cough syrup 100ml',
      form: 'Syrup',
      packSize: '100ml bottle',
      categoryId: 'c-cough',
      sellingPrice: 2500,
    ),
    Product(
      id: 'p-ibuprofen',
      barcode: '6001007034566',
      name: 'Ibuprofen 400mg',
      form: 'Tablets',
      packSize: 'Strip of 10',
      categoryId: 'c-pain',
      sellingPrice: 1200,
    ),
    Product(
      id: 'p-paracetamol',
      barcode: '6001007045678',
      name: 'Paracetamol 500mg',
      form: 'Tablets',
      packSize: 'Strip of 10',
      categoryId: 'c-pain',
      sellingPrice: 700,
    ),
    Product(
      id: 'p-omeprazole',
      barcode: '6001007067892',
      name: 'Omeprazole 20mg',
      form: 'Capsules',
      packSize: 'Box of 14',
      categoryId: 'c-digestive',
      sellingPrice: 3000,
    ),
  ];

  static List<Batch> sampleBatches(DateTime today) {
    DateTime inDays(int days) => today.add(Duration(days: days));
    Batch batch(
      String id,
      String productId,
      String number,
      int expiresInDays,
      int quantity,
      int costPrice,
    ) => Batch(
      id: id,
      pharmacyId: 'ph-amani',
      productId: productId,
      batchNumber: number,
      expiryDate: inDays(expiresInDays),
      quantity: quantity,
      costPrice: costPrice,
      receivedBy: 'u-owner',
      receivedByName: 'Aline Uwase',
      receivedAt: inDays(-60),
    );

    return [
      batch('b-mz2308', 'p-metronidazole', 'MZ2308', -25, 14, 900),
      batch('b-mz2410', 'p-metronidazole', 'MZ2410', 510, 9, 900),
      batch('b-amx-2309', 'amoxicillin-500', 'AMX-2309', -12, 40, 3000),
      batch('b-amx-2411', 'amoxicillin-500', 'AMX-2411', 200, 120, 3000),
      batch('b-cs-118', 'cough-syrup-100', 'CS-118', -3, 6, 1600),
      batch('b-ib2209', 'p-ibuprofen', 'IB2209', -10, 6, 700),
      batch('b-ib2311', 'p-ibuprofen', 'IB2311', 200, 40, 700),
      batch('b-pc2401', 'p-paracetamol', 'PC2401', 300, 120, 400),
      batch('b-om2402', 'p-omeprazole', 'OM2402', 45, 12, 1900),
    ];
  }
}
