import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/domain/entities/batch_allocation.dart';
import 'package:team30_app/features/pos/domain/entities/cart_item.dart';
import 'package:team30_app/features/pos/domain/entities/payment_method.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/domain/entities/pos_product.dart';
import 'package:team30_app/features/pos/domain/repositories/checkout_repository.dart';
import 'package:team30_app/features/pos/presentation/cubit/checkout_cubit.dart';
import 'package:team30_app/features/pos/presentation/cubit/checkout_state.dart';

class _CheckoutRepository implements CheckoutRepository {
  final Map<String, int> stock;
  int checkoutCount = 0;
  bool failCheckout = false;
  CheckoutRequest? lastRequest;

  _CheckoutRepository(this.stock);

  @override
  Future<void> checkout(CheckoutRequest request) async {
    checkoutCount++;
    lastRequest = request;
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

  group('payment method', () {
    Future<_CheckoutRepository> pay(String method, {int? cashReceived}) async {
      final repository = _CheckoutRepository({'b1': 5});
      final cubit = CheckoutCubit(repository);
      await cubit.checkout(
        items: [item],
        pharmacyId: 'ph1',
        saleId: 'sale-1',
        receiptNo: '0001',
        soldBy: 'u1',
        paymentMethod: method,
        cashReceived: cashReceived,
      );
      expect(cubit.state.status, CheckoutStatus.success, reason: method);
      return repository;
    }

    test('mobile money and card need no cash and give no change', () async {
      for (final method in [PaymentMethods.mobileMoney, PaymentMethods.card]) {
        final request = (await pay(method)).lastRequest!;
        expect(request.paymentMethod, method);
        expect(request.cashReceived, 2500, reason: 'recorded as paid in full');
        expect(request.change, 0);
      }
    });

    test('cash records the cash received and the change', () async {
      final request = (await pay(
        PaymentMethods.cash,
        cashReceived: 3000,
      )).lastRequest!;
      expect(request.cashReceived, 3000);
      expect(request.change, 500);
    });

    blocTest<CheckoutCubit, CheckoutState>(
      'cash sale fails without enough cash',
      build: () => CheckoutCubit(_CheckoutRepository({'b1': 5})),
      act: (cubit) => cubit.checkout(
        items: [item],
        pharmacyId: 'ph1',
        saleId: 'sale-1',
        receiptNo: '0001',
        soldBy: 'u1',
        paymentMethod: PaymentMethods.cash,
      ),
      expect: () => [
        const CheckoutState.failure('Insufficient cash received.'),
      ],
    );
  });

  test('concurrent checkout cannot oversell stock', () async {
    final repository = _CheckoutRepository({'b1': 5});
    final cubit = CheckoutCubit(repository);

    await Future.wait([checkout(cubit), checkout(cubit)]);

    expect(repository.stock['b1'], 0);
  });
}
