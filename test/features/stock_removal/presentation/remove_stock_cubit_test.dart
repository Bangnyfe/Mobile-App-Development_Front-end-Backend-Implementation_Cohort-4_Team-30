import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/stock_removal/data/fake_stock_removal_repository.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removal_reason.dart';
import 'package:team30_app/features/stock_removal/domain/entities/stock_removal.dart';
import 'package:team30_app/features/stock_removal/domain/repositories/stock_removal_repository.dart';
import 'package:team30_app/features/stock_removal/presentation/cubit/remove_stock_cubit.dart';

class _MockRepository extends Mock implements StockRemovalRepository {}

void main() {
  final now = DateTime(2026, 11, 21, 10, 14);
  late FakeStockRemovalRepository repository;

  setUpAll(
    () => registerFallbackValue(
      const StockRemovalRequest(
        productId: 'p',
        batchId: 'b',
        quantity: 1,
        reason: RemovalReason.damaged,
      ),
    ),
  );

  setUp(() => repository = FakeStockRemovalRepository(clock: () => now));

  RemoveStockCubit build() => RemoveStockCubit(repository, clock: () => now);

  test('loads the products with stock', () async {
    final cubit = build();
    await cubit.start();

    expect(cubit.state.status, RemoveStockStatus.ready);
    expect(cubit.state.products, hasLength(5));
    expect(cubit.state.batch, isNull);
    expect(cubit.state.canContinue, isFalse);
  });

  test('shows a message when the stock cannot be loaded', () async {
    final failing = _MockRepository();
    when(() => failing.loadProducts()).thenThrow(Exception('offline'));
    final cubit = RemoveStockCubit(failing, clock: () => now);

    await cubit.start();

    expect(cubit.state.status, RemoveStockStatus.loadFailure);
    expect(cubit.state.message, RemoveStockCubit.loadFailedMessage);
  });

  test('search filters by name', () async {
    final cubit = build();
    await cubit.start();

    cubit.search('ibu');

    expect(cubit.state.visibleProducts.map((p) => p.name), ['Ibuprofen 400mg']);
  });

  test('choosing a product offers its expired batch with all units and '
      'Expired suggested', () async {
    final cubit = build();
    await cubit.start();

    cubit.selectProduct('p-metronidazole');

    expect(cubit.state.batch!.batchNumber, 'MZ2308');
    expect(cubit.state.quantity, 14);
    expect(cubit.state.suggestedReason, RemovalReason.expired);
    expect(cubit.state.reason, isNull);
    expect(cubit.state.canContinue, isTrue);
    expect(cubit.state.costValue, 15400);
  });

  test('an in-date batch starts at 1 and stays within its units', () async {
    final cubit = build();
    await cubit.start();
    cubit.selectProduct('p-metronidazole');

    cubit.selectBatch('b-mz2410');
    expect(cubit.state.quantity, 1);
    expect(cubit.state.suggestedReason, isNull);

    cubit.decrement();
    expect(cubit.state.quantity, 1);

    cubit.setQuantity(50);
    expect(cubit.state.quantity, 9);

    cubit.setQuantity(4);
    cubit.increment();
    expect(cubit.state.quantity, 5);

    cubit.removeAll();
    expect(cubit.state.quantity, 9);
  });

  test('cannot save without a reason, or Other without a note', () async {
    final cubit = build();
    await cubit.start();
    cubit.selectProduct('p-paracetamol');

    expect(cubit.state.canSubmit, isFalse);
    expect(cubit.state.reasonError, 'Choose a reason to continue.');

    cubit.selectReason(RemovalReason.other);
    expect(cubit.state.canSubmit, isFalse);

    cubit.setNote('Given to the clinic as samples');
    expect(cubit.state.canSubmit, isTrue);
  });

  test(
    'opening from a notification pre-selects the batch and reason',
    () async {
      final cubit = build();

      await cubit.start(
        productId: 'p-ibuprofen',
        batchId: 'b-ib2209',
        suggestedReason: RemovalReason.expired,
      );

      expect(cubit.state.batch!.batchNumber, 'IB2209');
      expect(cubit.state.quantity, 6);
      expect(cubit.state.reason, RemovalReason.expired);
      expect(cubit.state.canSubmit, isTrue);
    },
  );

  test('saving shows progress, then the recorded removal and the lower '
      'stock', () async {
    final cubit = build();
    await cubit.start();
    cubit
      ..selectProduct('p-metronidazole')
      ..selectReason(RemovalReason.expired);
    final states = <RemoveStockState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.submit();
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(states.map((s) => s.submitStatus), [
      SubmitStatus.submitting,
      SubmitStatus.success,
    ]);
    expect(states.last.result!.quantity, 14);
    expect(states.last.result!.costValue, 15400);
    expect(states.last.product!.totalUnits, 9);
    expect(repository.removals, hasLength(1));
  });

  test('a failed save keeps the selection and shows the message', () async {
    final failing = _MockRepository();
    final products = await repository.loadProducts();
    when(() => failing.loadProducts()).thenAnswer((_) async => products);
    when(() => failing.removeStock(any())).thenThrow(
      const StockRemovalFailure('Only 10 units are left in this batch.'),
    );
    final cubit = RemoveStockCubit(failing, clock: () => now);
    await cubit.start();
    cubit
      ..selectProduct('p-metronidazole')
      ..selectReason(RemovalReason.expired);

    await cubit.submit();

    expect(cubit.state.submitStatus, SubmitStatus.failure);
    expect(cubit.state.message, 'Only 10 units are left in this batch.');
    expect(cubit.state.batch!.batchNumber, 'MZ2308');
    expect(cubit.state.result, isNull);
  });
}
