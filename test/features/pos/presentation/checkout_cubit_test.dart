import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/domain/entities/batch_allocation.dart';
import 'package:team30_app/features/pos/domain/entities/cart_item.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/domain/entities/pos_product.dart';
import 'package:team30_app/features/pos/domain/repositories/checkout_repository.dart';
import 'package:team30_app/features/pos/presentation/cubit/checkout_cubit.dart';
import 'package:team30_app/features/pos/presentation/cubit/checkout_state.dart';

class _CheckoutRepository implements CheckoutRepository {
  final Map<String, int> stock;
  int checkoutCount = 0;
  bool failCheckout = false;

  _CheckoutRepository(this.stock);

  @override
  Future<void> checkout(CheckoutRequest request) async {
    checkoutCount++;
    if (failCheckout) throw const CheckoutException('Checkout failed.');

    for (final item in request.items) {
      for (final allocation in item.allocations) {
        final available = stock[allocation.batchId] ?? 0;
        if (available < allocation.quantity) {
          throw CheckoutException(
            'Insufficient stock. Available: $available, '
            'Requested: ${allocation.quantity}.',
          );
        }
      }
    }

    for (final item in request.items) {
      for (final allocation in item.allocations) {
        stock[allocation.batchId] =
            stock[allocation.batchId]! - allocation.quantity;
      }
    }
  }
}

void main() {
  final product = PosProduct(
    id: 'p1',
    barcode: '123',
    name: 'Product',
    sellingPrice: 500,
  );
  final batch = PosBatch(
    id: 'b1',
    batchNumber: 'B001',
    expiryDate: DateTime(2027, 1, 1),
    quantity: 5,
  );
  final item = CartItem(
    product: product,
    batch: batch,
    quantity: 5,
    allocations: const [
      BatchAllocation(batchId: 'b1', batchNumber: 'B001', quantity: 5),
    ],
  );

  Future<void> checkout(CheckoutCubit cubit) => cubit.checkout(
    items: [item],
    pharmacyId: 'ph1',
    saleId: 'sale-1',
    receiptNo: '0001',
    soldBy: 'u1',
    paymentMethod: 'Cash',
    cashReceived: 3000,
  );

  blocTest<CheckoutCubit, CheckoutState>(
    'deducts stock only after complete successful checkout',
    build: () => CheckoutCubit(_CheckoutRepository({'b1': 5})),
  );

  test('deducts the allocated quantities', () async {
    final repository = _CheckoutRepository({'b1': 3, 'b2': 4});
    final cubit = CheckoutCubit(repository);
    final split = CartItem(
      product: product,
      batch: batch,
      quantity: 5,
      allocations: const [
        BatchAllocation(batchId: 'b1', batchNumber: 'B001', quantity: 3),
        BatchAllocation(batchId: 'b2', batchNumber: 'B002', quantity: 2),
      ],
    );

    await cubit.checkout(
      items: [split],
      pharmacyId: 'ph1',
      saleId: 'sale-1',
      receiptNo: '0001',
      soldBy: 'u1',
      paymentMethod: 'Cash',
      cashReceived: 3000,
    );

    expect(repository.stock, {'b1': 0, 'b2': 2});
  });

  test('failed checkout does not partially deduct stock', () async {
    final repository = _CheckoutRepository({'b1': 3, 'b2': 1});
    final cubit = CheckoutCubit(repository);
    final split = CartItem(
      product: product,
      batch: batch,
      quantity: 5,
      allocations: const [
        BatchAllocation(batchId: 'b1', batchNumber: 'B001', quantity: 3),
        BatchAllocation(batchId: 'b2', batchNumber: 'B002', quantity: 2),
      ],
    );

    await cubit.checkout(
      items: [split],
      pharmacyId: 'ph1',
      saleId: 'sale-1',
      receiptNo: '0001',
      soldBy: 'u1',
      paymentMethod: 'Cash',
      cashReceived: 3000,
    );

    expect(repository.stock, {'b1': 3, 'b2': 1});
    expect(cubit.state.status, CheckoutStatus.failure);
  });

  test('concurrent checkout cannot oversell stock', () async {
    final repository = _CheckoutRepository({'b1': 5});
    final cubit = CheckoutCubit(repository);

    await Future.wait([checkout(cubit), checkout(cubit)]);

    expect(repository.stock['b1'], 0);
  });
}
