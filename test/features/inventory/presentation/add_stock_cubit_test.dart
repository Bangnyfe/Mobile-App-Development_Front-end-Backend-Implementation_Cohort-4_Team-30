import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/inventory/data/fake_inventory_repository.dart';
import 'package:team30_app/features/inventory/domain/entities/product.dart';
import 'package:team30_app/features/inventory/domain/inventory_failure.dart';
import 'package:team30_app/features/inventory/presentation/cubit/add_stock_cubit.dart';
import 'package:team30_app/features/inventory/presentation/cubit/register_product_cubit.dart';
import 'package:team30_app/features/scanner/domain/entities/scanned_code.dart';

import '../inventory_test_helpers.dart';

void main() {
  late FakeInventoryRepository repository;

  setUp(() {
    repository = FakeInventoryRepository(clock: () => inventoryToday);
  });

  group('AddStockCubit', () {
    late AddStockCubit cubit;

    setUp(() {
      cubit = AddStockCubit(
        repository,
        receivedBy: 'u1',
        receivedByName: 'Aline Uwase',
      );
      addTearDown(cubit.close);
    });

    test('starts on the scan step', () {
      expect(cubit.state, const AddStockScan());
    });

    test('a known barcode goes to the batch details with the scan', () async {
      final code = ScannedCode(
        gtin: '6001007023454',
        batchNumber: 'AMX-9',
        expiryDate: DateTime(2028, 6, 30),
      );

      await cubit.scanned(code);

      final state = cubit.state as AddStockDetails;
      expect(state.product.name, 'Amoxicillin 500mg');
      expect(state.code, code);
    });

    test('an unknown barcode asks to register the product', () async {
      const code = ScannedCode(gtin: '6001007078904');

      await cubit.scanned(code);

      expect(cubit.state, const AddStockNotRegistered(code));
    });

    test('after registering, keeps the scanned batch details', () async {
      final code = ScannedCode(
        gtin: '6001007078904',
        batchNumber: 'NEW-1',
        expiryDate: DateTime(2028, 1, 31),
      );
      await cubit.scanned(code);
      const product = Product(
        id: 'p-new',
        barcode: '6001007078904',
        name: 'Zinc 20mg',
        sellingPrice: 300,
      );

      cubit.productRegistered(product);

      expect(cubit.state, AddStockDetails(product: product, code: code));
    });

    test('opened from a product, skips the scan', () async {
      await cubit.start(productId: 'p-paracetamol');

      expect((cubit.state as AddStockDetails).product.id, 'p-paracetamol');
    });

    test('a deleted product shows not found', () async {
      await cubit.start(productId: 'gone');

      expect(cubit.state, const AddStockFailure(InventoryFailure.notFound));
    });

    test('save adds the batch, with who received it', () async {
      await cubit.start(productId: 'p-paracetamol');

      await cubit.save(
        batchNumber: ' PC2501 ',
        expiryDate: DateTime(2028, 3, 31, 15, 45),
        quantity: 200,
        costPrice: 350,
      );

      final done = cubit.state as AddStockDone;
      expect(done.batch.batchNumber, 'PC2501');
      expect(done.batch.expiryDate, DateTime(2028, 3, 31));
      final saved = repository.batches.last;
      expect(saved.productId, 'p-paracetamol');
      expect(saved.quantity, 200);
      expect(saved.costPrice, 350);
      expect(saved.receivedBy, 'u1');
      expect(saved.receivedByName, 'Aline Uwase');
    });

    test('a failed save stays on the form with the message', () async {
      await cubit.start(productId: 'p-paracetamol');
      repository.fail = true;

      await cubit.save(
        batchNumber: 'PC2501',
        expiryDate: DateTime(2028, 3, 31),
        quantity: 200,
        costPrice: 350,
      );

      final state = cubit.state as AddStockDetails;
      expect(state.errorMessage, InventoryFailure.generic);
      expect(state.saving, isFalse);
    });

    test('a failed lookup shows the message', () async {
      repository.fail = true;

      await cubit.scanned(const ScannedCode(gtin: '6001007023454'));

      expect(cubit.state, const AddStockFailure(InventoryFailure.generic));
    });
  });

  group('RegisterProductCubit', () {
    late RegisterProductCubit cubit;

    setUp(() {
      cubit = RegisterProductCubit(repository);
      addTearDown(cubit.close);
    });

    const zinc = Product(
      id: '',
      barcode: '6001007078904',
      name: 'Zinc 20mg',
      sellingPrice: 300,
    );

    test('offers the categories', () async {
      cubit.start();
      await pumpEventQueue();

      expect(cubit.state.categories.map((c) => c.name), [
        'Antibiotics',
        'Cough & cold',
        'Digestive',
        'Pain relief',
      ]);
    });

    test('saves the product', () async {
      await cubit.save(zinc);

      expect(cubit.state.saved?.name, 'Zinc 20mg');
      expect(cubit.state.saved?.id, isNotEmpty);
    });

    test('a taken barcode shows the message', () async {
      await cubit.save(zinc.copyWith(barcode: '6001007023454'));

      expect(cubit.state.saved, isNull);
      expect(cubit.state.errorMessage, InventoryFailure.duplicateBarcode);
    });

    test('adds a category', () async {
      final category = await cubit.addCategory(' Vitamins ');

      expect(category?.name, 'Vitamins');
      expect(repository.categories.map((c) => c.name), contains('Vitamins'));
    });
  });
}
