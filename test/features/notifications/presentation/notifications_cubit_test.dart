import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/notifications/data/in_memory_seen_alerts_repository.dart';
import 'package:team30_app/features/notifications/domain/entities/stock_alert.dart';
import 'package:team30_app/features/notifications/domain/repositories/seen_alerts_repository.dart';
import 'package:team30_app/features/notifications/domain/repositories/stock_alerts_repository.dart';
import 'package:team30_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:team30_app/features/settings/domain/entities/app_settings.dart';

import '../notifications_test_helpers.dart';

void main() {
  late StreamController<AppSettings> settings;

  setUp(() => settings = StreamController<AppSettings>.broadcast());
  tearDown(() => settings.close());

  NotificationsCubit buildCubit({
    required StockAlertsRepository stock,
    SeenAlertsRepository? seen,
    AppSettings initialSettings = const AppSettings(),
  }) {
    final cubit = NotificationsCubit(
      stockRepository: stock,
      seenRepository: seen ?? InMemorySeenAlertsRepository(),
      initialSettings: initialSettings,
      settingsChanges: settings.stream,
      clock: () => testToday,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  /// Lets streams and futures deliver their values.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starts loading', () {
    final cubit = buildCubit(stock: FixedStockAlertsRepository(const []));

    expect(cubit.state, const NotificationsLoading());
    expect(cubit.state.newCount, 0);
  });

  test('works out the alerts from the stock', () async {
    final cubit = buildCubit(
      stock: FixedStockAlertsRepository([
        productExpiringIn(-2, id: 'old'),
        productExpiringIn(10, id: 'soon'),
      ]),
    );

    await cubit.start();
    await settle();

    final state = cubit.state as NotificationsLoaded;
    expect(state.alerts.map((a) => a.type), [
      StockAlertType.expired,
      StockAlertType.expiringSoon,
    ]);
    expect(state.newCount, 2);
  });

  test('no stock problems means an empty list, not an error', () async {
    final cubit = buildCubit(
      stock: FixedStockAlertsRepository([productExpiringIn(300)]),
    );

    await cubit.start();
    await settle();

    expect(cubit.state, const NotificationsLoaded(alerts: []));
  });

  test('updates live when the stock changes', () async {
    final stock = StubStockAlertsRepository();
    addTearDown(stock.controller.close);
    final cubit = buildCubit(stock: stock);

    await cubit.start();
    stock.controller.add([productExpiringIn(300)]);
    await settle();
    expect((cubit.state as NotificationsLoaded).alerts, isEmpty);

    stock.controller.add([productExpiringIn(5)]);
    await settle();
    expect((cubit.state as NotificationsLoaded).alerts, hasLength(1));
  });

  test('works the alerts out again when the settings change', () async {
    final cubit = buildCubit(
      stock: FixedStockAlertsRepository([productExpiringIn(60)]),
      initialSettings: const AppSettings(expiryAlertDays: 30),
    );

    await cubit.start();
    await settle();
    expect((cubit.state as NotificationsLoaded).alerts, isEmpty);

    settings.add(const AppSettings(expiryAlertDays: 90));
    await settle();
    expect((cubit.state as NotificationsLoaded).alerts, hasLength(1));
  });

  test('a settings change before start finishes is not missed', () async {
    final cubit = buildCubit(
      stock: FixedStockAlertsRepository([productExpiringIn(60)]),
      initialSettings: const AppSettings(expiryAlertDays: 90),
    );

    // E.g. the saved settings finish loading while start() is waiting.
    final starting = cubit.start();
    settings.add(const AppSettings(expiryAlertDays: 30));
    await starting;
    await settle();

    expect((cubit.state as NotificationsLoaded).alerts, isEmpty);
  });

  test('alerts seen before are not new', () async {
    final cubit = buildCubit(
      stock: FixedStockAlertsRepository([
        productExpiringIn(-2, id: 'old'),
        productExpiringIn(10, id: 'soon'),
      ]),
      seen: InMemorySeenAlertsRepository({'expired:b-old'}),
    );

    await cubit.start();
    await settle();

    final state = cubit.state as NotificationsLoaded;
    expect(state.newCount, 1);
    expect(state.isNew(state.alerts.first), isFalse);
    expect(state.isNew(state.alerts.last), isTrue);
  });

  test('markAllSeen clears the count and saves only current IDs', () async {
    final seen = InMemorySeenAlertsRepository({'low:gone'});
    final cubit = buildCubit(
      stock: FixedStockAlertsRepository([productExpiringIn(10, id: 'soon')]),
      seen: seen,
    );
    await cubit.start();
    await settle();

    await cubit.markAllSeen();

    expect(cubit.state.newCount, 0);
    expect(await seen.loadSeenIds(), {'expiring:b-soon'});
  });

  test('a batch that goes from expiring to expired is new again', () async {
    final stock = StubStockAlertsRepository();
    addTearDown(stock.controller.close);
    final cubit = buildCubit(stock: stock);
    await cubit.start();

    stock.controller.add([productExpiringIn(1)]);
    await settle();
    await cubit.markAllSeen();
    expect(cubit.state.newCount, 0);

    stock.controller.add([productExpiringIn(-1)]);
    await settle();
    expect(cubit.state.newCount, 1);
  });

  test('if seen alerts cannot be loaded, every alert is new', () async {
    final cubit = buildCubit(
      stock: FixedStockAlertsRepository([productExpiringIn(10)]),
      seen: FailingSeenAlertsRepository(),
    );

    await cubit.start();
    await settle();
    expect(cubit.state.newCount, 1);

    // Saving fails too, but the badge still clears for now.
    await cubit.markAllSeen();
    expect(cubit.state.newCount, 0);
  });

  test('shows an error when the stock fails, and Try again recovers', () async {
    final stock = FixedStockAlertsRepository([
      productExpiringIn(10),
    ], fail: true);
    final cubit = buildCubit(stock: stock);

    await cubit.start();
    await settle();
    expect(
      cubit.state,
      const NotificationsFailure(NotificationsCubit.loadFailedMessage),
    );
    expect(cubit.state.newCount, 0);

    stock.fail = false;
    await cubit.start();
    await settle();
    expect(cubit.state.newCount, 1);
  });

  test('markAllSeen does nothing while loading', () async {
    final cubit = buildCubit(stock: FixedStockAlertsRepository(const []));

    await cubit.markAllSeen();

    expect(cubit.state, const NotificationsLoading());
  });
}
