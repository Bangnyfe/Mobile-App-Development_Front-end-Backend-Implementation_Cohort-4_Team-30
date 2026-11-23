import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:team30_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:team30_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:team30_app/features/settings/domain/entities/app_settings.dart';

import '../dashboard_test_data.dart';

/// Repository that replays whatever stream the test gives it, and records
/// the settings it was asked with.
class _StubDashboardRepository implements DashboardRepository {
  _StubDashboardRepository(this._stream) : _perSettings = null;

  _StubDashboardRepository.perSettings(this._perSettings)
    : _stream = const Stream.empty();

  final Stream<DashboardSummary> _stream;
  final Stream<DashboardSummary> Function(AppSettings settings)? _perSettings;
  final List<AppSettings> requested = [];

  @override
  Stream<DashboardSummary> watchSummary(AppSettings settings) {
    requested.add(settings);
    return _perSettings?.call(settings) ?? _stream;
  }
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
    expect: () => [
      const DashboardLoading(),
      const DashboardFailure(DashboardCubit.loadFailedMessage),
    ],
  );

  group('alert settings', () {
    const thirtyDays = AppSettings(expiryAlertDays: 30);
    const sixtyDays = AppSettings(expiryAlertDays: 60);

    test('asks for the summary with the current settings', () async {
      final repository = _StubDashboardRepository(Stream.value(summary));
      final cubit = DashboardCubit(repository, initialSettings: thirtyDays)
        ..start();
      await pumpEventQueue();

      expect(repository.requested, [thirtyDays]);
      await cubit.close();
    });

    test('works the summary out again when the alert settings change, '
        'keeping the old numbers until then', () async {
      final settings = StreamController<AppSettings>();
      final repository = _StubDashboardRepository.perSettings(
        (s) => Stream.value(
          buildSummary(todaySalesTotal: s.expiryAlertDays * 1000),
        ),
      );
      final cubit = DashboardCubit(
        repository,
        initialSettings: thirtyDays,
        settingsChanges: settings.stream,
      )..start();
      await pumpEventQueue();
      final states = <DashboardState>[];
      final listening = cubit.stream.listen(states.add);

      settings.add(sixtyDays);
      await pumpEventQueue();

      expect(repository.requested, [thirtyDays, sixtyDays]);
      expect(states, [DashboardLoaded(buildSummary(todaySalesTotal: 60000))]);
      await listening.cancel();
      await cubit.close();
      await settings.close();
    });

    test('ignores settings that don\'t change the numbers', () async {
      final settings = StreamController<AppSettings>();
      final repository = _StubDashboardRepository(Stream.value(summary));
      final cubit = DashboardCubit(
        repository,
        initialSettings: thirtyDays,
        settingsChanges: settings.stream,
      )..start();
      await pumpEventQueue();

      settings.add(
        const AppSettings(expiryAlertDays: 30, pushNotificationsEnabled: false),
      );
      await pumpEventQueue();

      expect(repository.requested, [thirtyDays]);
      await cubit.close();
      await settings.close();
    });

    test('settings that arrive before start are used when it starts', () async {
      final settings = StreamController<AppSettings>();
      final repository = _StubDashboardRepository(Stream.value(summary));
      final cubit = DashboardCubit(
        repository,
        initialSettings: thirtyDays,
        settingsChanges: settings.stream,
      );
      settings.add(sixtyDays);
      await pumpEventQueue();
      expect(repository.requested, isEmpty);

      cubit.start();
      await pumpEventQueue();

      expect(repository.requested, [sixtyDays]);
      await cubit.close();
      await settings.close();
    });
  });
}
