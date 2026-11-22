import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/stock_removal/data/fake_stock_removal_repository.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removal_reason.dart';
import 'package:team30_app/features/stock_removal/presentation/cubit/remove_stock_cubit.dart';

void main() {
  final now = DateTime(2026, 11, 22, 9, 30);
  late RemoveStockCubit cubit;

  setUp(() {
    cubit = RemoveStockCubit(
      FakeStockRemovalRepository(clock: () => now),
      clock: () => now,
    );
  });

  test('Continue needs a batch; back keeps the selection', () async {
    await cubit.start();
    expect(cubit.state.step, RemoveStockStep.chooseBatch);

    cubit.goToReason();
    expect(cubit.state.step, RemoveStockStep.chooseBatch);

    cubit
      ..selectProduct('p-metronidazole')
      ..goToReason();
    expect(cubit.state.step, RemoveStockStep.reason);

    cubit.backToBatch();
    expect(cubit.state.step, RemoveStockStep.chooseBatch);
    expect(cubit.state.batch!.batchNumber, 'MZ2308');
  });

  test('Change returns to the product list', () async {
    await cubit.start();
    cubit
      ..selectProduct('p-metronidazole')
      ..clearProduct();

    expect(cubit.state.product, isNull);
    expect(cubit.state.batch, isNull);
    expect(cubit.state.canContinue, isFalse);
  });

  test('a successful save moves to the confirmation', () async {
    await cubit.start();
    cubit
      ..selectProduct('p-metronidazole')
      ..goToReason()
      ..selectReason(RemovalReason.expired);

    await cubit.submit();

    expect(cubit.state.step, RemoveStockStep.done);
    expect(cubit.state.productUnits, 9);
  });

  test('from a notification it opens on the Reason step', () async {
    await cubit.start(
      productId: 'amoxicillin-500',
      batchId: 'b-amx-2309',
      suggestedReason: RemovalReason.expired,
    );

    expect(cubit.state.step, RemoveStockStep.reason);
    expect(cubit.state.fromNotification, isTrue);
    expect(cubit.state.quantity, 40);
  });

  test(
    'an unknown batch from a notification falls back to Choose batch',
    () async {
      await cubit.start(
        productId: 'no-such-product',
        batchId: 'no-such-batch',
        suggestedReason: RemovalReason.expired,
      );

      expect(cubit.state.step, RemoveStockStep.chooseBatch);
      expect(cubit.state.fromNotification, isFalse);
    },
  );
}
