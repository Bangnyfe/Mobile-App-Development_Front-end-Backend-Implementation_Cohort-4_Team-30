import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/features/scanner/presentation/pages/scanner_page.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:team30_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:team30_app/features/stock_removal/data/fake_stock_removal_repository.dart';
import 'package:team30_app/features/stock_removal/presentation/cubit/remove_stock_cubit.dart';
import 'package:team30_app/features/stock_removal/presentation/pages/remove_stock_page.dart';

import '../../scanner/scanner_test_helpers.dart';

const _metronidazole = '6001007012342';
const _gs = '\u001d';

void main() {
  final now = DateTime(2026, 11, 22, 9, 30);
  late FakeCamera camera;
  late RemoveStockCubit cubit;

  group('RemoveStockCubit.selectScanned', () {
    setUp(() async {
      cubit = RemoveStockCubit(
        FakeStockRemovalRepository(clock: () => now),
        clock: () => now,
      );
      addTearDown(cubit.close);
      await cubit.start();
    });

    test('picks the product, offering its earliest batch', () {
      expect(cubit.selectScanned(barcode: _metronidazole), isTrue);

      expect(cubit.state.product?.name, 'Metronidazole 400mg');
      expect(cubit.state.batch?.batchNumber, 'MZ2308');
    });

    test('picks the batch a DataMatrix named', () {
      cubit.selectScanned(barcode: _metronidazole, batchNumber: 'mz2410');

      expect(cubit.state.batch?.batchNumber, 'MZ2410');
      expect(cubit.state.quantity, 1);
    });

    test('an unknown batch number keeps the earliest batch', () {
      cubit.selectScanned(barcode: _metronidazole, batchNumber: 'NOPE');

      expect(cubit.state.batch?.batchNumber, 'MZ2308');
    });

    test('returns false for a barcode with no stock', () {
      expect(cubit.selectScanned(barcode: '0000000000000'), isFalse);
      expect(cubit.state.product, isNull);
    });
  });

  group('the scan button on Choose batch', () {
    Future<void> pumpPage(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      camera = FakeCamera();

      await tester.pumpWidget(
        ScannerCameraScope(
          cameraBuilder: camera.build,
          child: MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) =>
                      SettingsCubit(SharedPrefsSettingsRepository(prefs))
                        ..load(),
                ),
                BlocProvider(
                  create: (_) => RemoveStockCubit(
                    FakeStockRemovalRepository(clock: () => now),
                    clock: () => now,
                  )..start(),
                ),
              ],
              child: RemoveStockPage(clock: () => now),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Scan barcode'));
      await tester.pumpAndSettle();
    }

    testWidgets('a scanned DataMatrix opens its product and batch', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(find.text('Scan to remove'), findsOneWidget);

      camera.see(
        '010${_metronidazole}17280401'
        '10MZ2410$_gs'
        '21SN1',
      );
      await tester.pumpAndSettle();

      expect(find.byType(ScannerPage), findsNothing);
      expect(find.text('Metronidazole 400mg'), findsOneWidget);
      expect(find.text('Search product name or barcode'), findsNothing);
    });

    testWidgets('an unknown barcode says so and stays on the list', (
      tester,
    ) async {
      await pumpPage(tester);

      camera.see('96385074');
      await tester.pumpAndSettle();

      expect(
        find.text('No product with barcode 96385074 has stock to remove.'),
        findsOneWidget,
      );
      expect(find.text('Search product name or barcode'), findsOneWidget);
    });
  });
}
