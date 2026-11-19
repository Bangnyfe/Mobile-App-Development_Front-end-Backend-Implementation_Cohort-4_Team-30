import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/sales/presentation/cubit/sale_details_cubit.dart';

import '../sales_test_helpers.dart';

void main() {
  final sale = buildSale(id: 's1', createdAt: DateTime(2026, 11, 19, 10));

  test('starts in the loading state', () {
    final cubit = SaleDetailsCubit(StubSalesRepository(), 's1');
    expect(cubit.state, const SaleDetailsLoading());
    cubit.close();
  });

  blocTest<SaleDetailsCubit, SaleDetailsState>(
    'emits the sale',
    build: () => SaleDetailsCubit(StubSalesRepository(sales: [sale]), 's1'),
    act: (cubit) => cubit.load(),
    expect: () => [const SaleDetailsLoading(), SaleDetailsLoaded(sale)],
  );

  blocTest<SaleDetailsCubit, SaleDetailsState>(
    'emits not found for an unknown ID',
    build: () =>
        SaleDetailsCubit(StubSalesRepository(sales: [sale]), 'missing'),
    act: (cubit) => cubit.load(),
    expect: () => [const SaleDetailsLoading(), const SaleDetailsNotFound()],
  );

  blocTest<SaleDetailsCubit, SaleDetailsState>(
    'emits a failure when the sale fails to load',
    build: () => SaleDetailsCubit(StubSalesRepository(fail: true), 's1'),
    act: (cubit) => cubit.load(),
    expect: () => [
      const SaleDetailsLoading(),
      const SaleDetailsFailure(SaleDetailsCubit.loadFailedMessage),
    ],
  );
}
