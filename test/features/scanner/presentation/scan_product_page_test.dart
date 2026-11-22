import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/features/scanner/data/fake_product_lookup_repository.dart';
import 'package:team30_app/features/scanner/presentation/cubit/scan_cubit.dart';
import 'package:team30_app/features/scanner/presentation/pages/scan_product_page.dart';
import 'package:team30_app/features/scanner/presentation/pages/scanner_page.dart';

import '../scanner_test_helpers.dart';

const _metronidazole = '6001007012342';
const _gs = '\u001d';

void main() {
  final now = DateTime(2026, 11, 21, 10);
  late FakeCamera camera;
  late FakeProductLookupRepository repository;

  setUp(() {
    camera = FakeCamera();
    repository = FakeProductLookupRepository(clock: () => now);
  });

  Future<void> pumpSell(
    WidgetTester tester, {
    Size size = const Size(1080, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScannerCameraScope(
        cameraBuilder: camera.build,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: BlocProvider(
            create: (_) => ScanCubit(repository),
            child: ScanProductPage(clock: () => now),
          ),
        ),
      ),
    );
  }

  Future<void> scan(WidgetTester tester, String raw, {String? button}) async {
    await tester.tap(find.text(button ?? 'Scan barcode'));
    await tester.pumpAndSettle();
    expect(find.text('Scan to sell'), findsOneWidget);
    camera.see(raw);
    await tester.pumpAndSettle();
  }

  testWidgets('starts by asking for a scan', (tester) async {
    await pumpSell(tester);

    expect(find.text('Scan a product to sell'), findsOneWidget);
  });

  testWidgets('a scanned barcode shows the product, price and batches', (
    tester,
  ) async {
    await pumpSell(tester);

    await scan(tester, _metronidazole);

    expect(find.byType(ScannerPage), findsNothing);
    expect(find.text('Product found'), findsOneWidget);
    expect(find.text('Metronidazole 400mg'), findsOneWidget);
    expect(find.text('Tablets · strip of 10'), findsOneWidget);
    expect(find.text('RWF 1,500'), findsOneWidget);
    // 14 expired units can't be sold; 9 in date can.
    expect(find.text('9 units to sell'), findsOneWidget);
    expect(find.text('Batch MZ2308'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Sell first'), findsOneWidget);
    expect(find.text('Scanned'), findsNothing);
  });

  testWidgets('a DataMatrix from an expired batch warns not to sell it', (
    tester,
  ) async {
    await pumpSell(tester);

    await scan(
      tester,
      '010${_metronidazole}17261027'
      '10MZ2308$_gs'
      '21SN1',
    );

    expect(
      find.text(
        'This pack is from batch MZ2308, expiring 27 Oct 2026. '
        'It has expired: do not sell it.',
      ),
      findsOneWidget,
    );
    expect(find.text('Scanned'), findsOneWidget);
  });

  testWidgets('a batch missing from the records is pointed out', (
    tester,
  ) async {
    await pumpSell(tester);

    await scan(tester, '010${_metronidazole}10ZZ999');

    expect(
      find.text(
        "This pack is from batch ZZ999. That batch isn't in your stock "
        'records.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an unknown barcode is not found, and can be scanned again', (
    tester,
  ) async {
    await pumpSell(tester);

    await scan(tester, '96385074');

    expect(find.text('Product not found'), findsOneWidget);
    expect(find.textContaining('96385074'), findsOneWidget);

    await scan(tester, _metronidazole, button: 'Scan again');

    expect(find.text('Metronidazole 400mg'), findsOneWidget);
  });

  testWidgets('a failed lookup can be tried again', (tester) async {
    repository.fail = true;
    await pumpSell(tester);

    await scan(tester, _metronidazole);
    expect(find.text(ScanCubit.lookupFailedMessage), findsOneWidget);

    repository.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Metronidazole 400mg'), findsOneWidget);
  });

  testWidgets('closing the scanner keeps the page as it was', (tester) async {
    await pumpSell(tester);

    await tester.tap(find.text('Scan barcode'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(find.text('Scan a product to sell'), findsOneWidget);
  });

  testWidgets('the found product fits in landscape', (tester) async {
    await pumpSell(tester, size: const Size(2400, 1080));

    await scan(
      tester,
      '010${_metronidazole}17261027'
      '10MZ2308',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Scan another product'), findsOneWidget);
  });
}
