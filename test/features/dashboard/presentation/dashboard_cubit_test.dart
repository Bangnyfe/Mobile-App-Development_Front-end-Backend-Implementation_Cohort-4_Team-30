import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:team30_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:team30_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';

import '../dashboard_test_data.dart';

/// Repository that replays whatever stream the test gives it.
class _StubDashboardRepository implements DashboardRepository {
  _StubDashboardRepository(this._stream);

  final Stream<DashboardSummary> _stream;

  @override
  Stream<DashboardSummary> watchSummary() => _stream;
}

void main() {
  final summary = buildSummary();
  final updated = buildSummary(todaySalesTotal: 291400);

  test('starts in the loading state', () {
    final cubit = DashboardCubit(
      _StubDashboardRepository(Stream.value(summary)),
    );
    expect(cubit.state, const DashboardLoading());
    cubit.close();
  });

  blocTest<DashboardCubit, DashboardState>(
    'emits loaded with each summary the repository streams',
    build: () => DashboardCubit(
      _StubDashboardRepository(Stream.fromIterable([summary, updated])),
    ),
    act: (cubit) => cubit.start(),
    expect: () => [
      const DashboardLoading(),
      DashboardLoaded(summary),
      DashboardLoaded(updated),
    ],
  );

  blocTest<DashboardCubit, DashboardState>(
    'emits a failure message when the repository errors',
    build: () => DashboardCubit(
      _StubDashboardRepository(Stream.error(Exception('offline'))),
    ),
    act: (cubit) => cubit.start(),
    expect: () => [const DashboardLoading(), isA<DashboardFailure>()],
  );
}
