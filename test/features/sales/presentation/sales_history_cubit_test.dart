import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/sales/domain/entities/sales_day.dart';
import 'package:team30_app/features/sales/domain/repositories/sales_repository.dart';
import 'package:team30_app/features/sales/presentation/cubit/sales_history_cubit.dart';

import '../sales_test_helpers.dart';

void main() {
  final sales = [
    buildSale(id: 'a', createdAt: DateTime(2026, 11, 19, 10)),
    buildSale(id: 'b', createdAt: DateTime(2026, 11, 18, 10)),
  ];

  test('starts in the loading state', () {
    final cubit = SalesHistoryCubit(StubSalesRepository());
    expect(cubit.state, const SalesHistoryLoading());
    cubit.close();
  });

  blocTest<SalesHistoryCubit, SalesHistoryState>(
    'emits the sales grouped by day',
    build: () => SalesHistoryCubit(StubSalesRepository(sales: sales)),
    act: (cubit) => cubit.start(),
    expect: () => [
      const SalesHistoryLoading(),
      SalesHistoryLoaded(days: groupSalesByDay(sales)),
    ],
  );

  blocTest<SalesHistoryCubit, SalesHistoryState>(
    'flags when the history reached the limit',
    build: () => SalesHistoryCubit(
      StubSalesRepository(
        sales: [
          for (var i = 0; i < SalesRepository.defaultLimit; i++)
            buildSale(id: '$i', createdAt: DateTime(2026, 11, 19)),
        ],
      ),
    ),
    act: (cubit) => cubit.start(),
    verify: (cubit) =>
        expect((cubit.state as SalesHistoryLoaded).isAtLimit, isTrue),
  );

  blocTest<SalesHistoryCubit, SalesHistoryState>(
    'emits a failure when the sales fail to load',
    build: () => SalesHistoryCubit(StubSalesRepository(fail: true)),
    act: (cubit) => cubit.start(),
    expect: () => [
      const SalesHistoryLoading(),
      const SalesHistoryFailure(SalesHistoryCubit.loadFailedMessage),
    ],
  );
}
