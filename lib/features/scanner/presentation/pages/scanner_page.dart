import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/scanned_code.dart';
import '../../domain/gs1_parser.dart';
import '../widgets/camera_view.dart';
import '../widgets/type_barcode_dialog.dart';

/// Builds the live camera, calling `onCode` with the raw text of every
/// barcode it sees. Tests pass one without a real camera.
typedef ScannerCameraBuilder = Widget Function(
  BuildContext context,
  ValueChanged<String> onCode,
);

/// Gives every scanner opened below it the same camera. The app uses the
/// real camera; widget tests wrap the app in one with a fake camera.
class ScannerCameraScope extends InheritedWidget {
  const ScannerCameraScope({
    super.key,
    required this.cameraBuilder,
    required super.child,
  });

  final ScannerCameraBuilder cameraBuilder;

  static ScannerCameraBuilder? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ScannerCameraScope>()
      ?.cameraBuilder;

  @override
  bool updateShouldNotify(ScannerCameraScope oldWidget) =>
      cameraBuilder != oldWidget.cameraBuilder;
}

/// The shared barcode scanner, used by Sell, Add stock and Remove stock.
///
/// Opens full screen over the tabs and closes with the [ScannedCode] of the
/// first product barcode it reads, or null if the user goes back. The
/// barcode can also be typed, for damaged labels or phones without a
/// camera.
class ScannerPage extends StatefulWidget {
  const ScannerPage({
    super.key,
    this.title = 'Scan barcode',
    this.cameraBuilder,
  });

  final String title;

  /// Defaults to [ScannerCameraScope], then the phone's camera.
  final ScannerCameraBuilder? cameraBuilder;

  /// Opens the scanner and waits for a code. Null if the user closed it.
  static Future<ScannedCode?> open(
    BuildContext context, {
    String title = 'Scan barcode',
  }) {
    final cameraBuilder = ScannerCameraScope.maybeOf(context);
    return Navigator.of(context, rootNavigator: true).push<ScannedCode>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ScannerPage(title: title, cameraBuilder: cameraBuilder),
      ),
    );
  }

  static const notABarcodeMessage =
      "That code isn't a product barcode. Try again or type the number.";

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  /// Set once a code is accepted, so a camera that keeps reporting the same
  /// barcode closes the page only once.
  bool _done = false;
  String? _lastRejected;
  String? _message;

  void _onCode(String raw) {
    if (_done || !mounted) return;
    final code = Gs1Parser.parse(raw);
    if (code == null) {
      // The camera reports the same code many times a second: only react
      // when a different one comes into view.
      if (raw == _lastRejected) return;
      setState(() {
        _lastRejected = raw;
        _message = ScannerPage.notABarcodeMessage;
      });
      return;
    }
    _finish(code);
  }

  void _finish(ScannedCode code) {
    if (_done) return;
    _done = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(code);
  }

  Future<void> _typeBarcode() async {
    final code = await TypeBarcodeDialog.show(context);
    if (code != null && mounted) _finish(code);
  }

  @override
  Widget build(BuildContext context) {
    final camera = widget.cameraBuilder ?? defaultCameraBuilder;
    final message = _message;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          camera(context, _onCode),
          const IgnorePointer(child: _ScanFrame()),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message != null) ...[
                    _Banner(message: message),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black54,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    onPressed: _typeBarcode,
                    icon: const Icon(Icons.keyboard_outlined),
                    label: const Text('Type the barcode'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The square to aim at, with a hint above it. Sized to fit in landscape.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = (constraints.biggest.shortestSide * 0.6).clamp(
          120.0,
          280.0,
        );
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Point the camera at the barcode on the pack',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Container(
                width: side,
                height: side * 0.7,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
