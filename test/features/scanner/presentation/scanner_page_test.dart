import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/scanner/domain/entities/scanned_code.dart';
import 'package:team30_app/features/scanner/presentation/pages/scanner_page.dart';
import 'package:team30_app/features/scanner/presentation/widgets/type_barcode_dialog.dart';

import '../scanner_test_helpers.dart';

const _ean = '6001007012342';

void main() {
  late FakeCamera camera;
  late List<ScannedCode?> results;

  setUp(() {
    camera = FakeCamera();
    results = [];
  });

  /// A page with an Open button that opens the scanner and records what it
  /// closes with.
  Future<void> pumpHost(
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
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async =>
                      results.add(await ScannerPage.open(context)),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the camera from the scope', (tester) async {
    await pumpHost(tester);

    expect(find.byType(ScannerPage), findsOneWidget);
    expect(camera.builds, greaterThan(0));
    expect(
      find.text('Point the camera at the barcode on the pack'),
      findsOneWidget,
    );
  });

  testWidgets('closes with the first product barcode it reads', (tester) async {
    await pumpHost(tester);

    camera.see(
      '010${_ean}17271231'
      '10MZ2308',
    );
    // The camera keeps reporting the code until the page has closed.
    camera.see(_ean);
    await tester.pumpAndSettle();

    expect(find.byType(ScannerPage), findsNothing);
    expect(results, [
      ScannedCode(
        gtin: _ean,
        expiryDate: DateTime(2027, 12, 31),
        batchNumber: 'MZ2308',
      ),
    ]);
  });

  testWidgets('a code that is not a product barcode keeps scanning', (
    tester,
  ) async {
    await pumpHost(tester);

    camera.see('https://example.com');
    await tester.pump();

    expect(find.byType(ScannerPage), findsOneWidget);
    expect(find.text(ScannerPage.notABarcodeMessage), findsOneWidget);

    camera.see(_ean);
    await tester.pumpAndSettle();

    expect(results, [const ScannedCode(gtin: _ean)]);
  });

  testWidgets('back closes without a code', (tester) async {
    await pumpHost(tester);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(find.byType(ScannerPage), findsNothing);
    expect(results, [null]);
  });

  testWidgets('a typed barcode is checked, then used', (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('Type the barcode'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '6001007012345');
    await tester.tap(find.text('Use barcode'));
    await tester.pump();

    expect(find.text(TypeBarcodeDialog.invalidMessage), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), _ean);
    await tester.tap(find.text('Use barcode'));
    await tester.pumpAndSettle();

    expect(find.byType(ScannerPage), findsNothing);
    expect(results, [const ScannedCode(gtin: _ean)]);
  });

  testWidgets('cancelling the typed barcode keeps scanning', (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('Type the barcode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(ScannerPage), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('fits in landscape without overflowing', (tester) async {
    await pumpHost(tester, size: const Size(2400, 1080));
    camera.see('not a barcode');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Type the barcode'), findsOneWidget);
  });
}
