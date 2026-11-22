import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The phone's camera, for [ScannerPage]'s default.
Widget defaultCameraBuilder(
  BuildContext context,
  ValueChanged<String> onCode,
) => CameraView(onCode: onCode);

/// Live camera that reports the barcodes found on medicine packs, with a
/// torch button for dim shelves.
class CameraView extends StatefulWidget {
  const CameraView({super.key, required this.onCode});

  final ValueChanged<String> onCode;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final _controller = MobileScannerController(
    // Box barcodes, plus the GS1 DataMatrix and GS1-128 codes that carry
    // the batch and expiry. Fewer formats scan faster.
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.code128,
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) widget.onCode(raw);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => _CameraUnavailable(error: error),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (!state.isRunning ||
                  state.torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }
              final on = state.torchState == TorchState.on;
              return IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                tooltip: on ? 'Turn torch off' : 'Turn torch on',
                onPressed: _controller.toggleTorch,
                icon: Icon(
                  on ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Shown instead of the preview when the camera can't be used. The Type
/// the barcode button stays available below it.
class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 96),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                denied
                    ? "Camera access is off. Allow it in your phone's "
                          'settings, or type the barcode instead.'
                    : "The camera isn't available. Type the barcode instead.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
