import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pinned_bottom_bar.dart';
import '../../../scanner/domain/gs1_parser.dart';
import '../../../scanner/presentation/cubit/scan_cubit.dart';
import '../../../scanner/presentation/pages/scanner_page.dart';
import '../../../scanner/presentation/widgets/camera_view.dart';
import '../../../scanner/presentation/widgets/type_barcode_dialog.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';

/// The Sell tab: scan a pack with the camera (or type its barcode) to open
/// Product found. Shows the cart's size and total.
class SellPage extends StatefulWidget {
  const SellPage({super.key, this.clock = DateTime.now});

  /// For tests; the app uses the real time.
  final DateTime Function() clock;

  static const searchByNameMessage =
      "Search by name isn't available yet. Type the barcode number, "
      'or scan it.';

  static String notFoundMessage(String barcode) =>
      'No product with barcode $barcode';

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final _search = TextEditingController();

  /// The camera only runs while Sell is the screen on show: it stops under
  /// the other Sell screens, on other tabs, and while the barcode dialog is
  /// open, so it can't scan from behind them.
  final _cameraOn = ValueNotifier<bool>(true);
  GoRouter? _router;
  bool _dialogOpen = false;

  /// Codes seen before this are ignored: the camera reports the same pack
  /// many times a second, and it's often still in view when Sell returns.
  DateTime _ignoreUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// A barcode that wasn't found, ignored until another one is scanned so
  /// the same "not found" message doesn't repeat while it stays in view.
  String? _notFoundBarcode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router != _router) {
      _router?.routerDelegate.removeListener(_updateCamera);
      _router = router;
      router?.routerDelegate.addListener(_updateCamera);
      _updateCamera();
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_updateCamera);
    _cameraOn.dispose();
    _search.dispose();
    super.dispose();
  }

  void _updateCamera() {
    final router = _router;
    final onSell =
        router == null ||
        router.routerDelegate.currentConfiguration.uri.path == RoutePaths.sell;
    final on = onSell && !_dialogOpen;
    if (on && !_cameraOn.value) {
      _ignoreUntil = widget.clock().add(const Duration(seconds: 2));
    }
    _cameraOn.value = on;
  }

  void _onCode(String raw) {
    if (!mounted || !_cameraOn.value) return;
    final cubit = context.read<ScanCubit>();
    if (cubit.state is ScanLookingUp) return;
    final now = widget.clock();
    if (now.isBefore(_ignoreUntil)) return;
    final code = Gs1Parser.parse(raw);
    if (code == null || code.gtin == _notFoundBarcode) return;
    _ignoreUntil = now.add(const Duration(seconds: 2));
    cubit.lookUp(code);
  }

  Future<void> _enterBarcode() async {
    final cubit = context.read<ScanCubit>();
    _dialogOpen = true;
    _updateCamera();
    final code = await TypeBarcodeDialog.show(context);
    _dialogOpen = false;
    if (!mounted) return;
    _updateCamera();
    if (code != null) await cubit.lookUp(code);
  }

  void _submitSearch(String text) {
    final code = Gs1Parser.parse(text.trim());
    if (code == null) {
      _showMessage(SellPage.searchByNameMessage);
      return;
    }
    _search.clear();
    context.read<ScanCubit>().lookUp(code);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onScanState(BuildContext context, ScanState state) {
    final cubit = context.read<ScanCubit>();
    switch (state) {
      case ScanFound(:final found):
        _notFoundBarcode = null;
        cubit.reset();
        context.push(RoutePaths.sellProduct, extra: found);
      case ScanNotFound(:final code):
        _notFoundBarcode = code.gtin;
        _showMessage(SellPage.notFoundMessage(code.gtin));
        cubit.reset();
      case ScanFailure(:final message):
        _showMessage(message);
        cubit.reset();
      case ScanIdle() || ScanLookingUp():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = ScannerCameraScope.maybeOf(context) ?? defaultCameraBuilder;

    return Scaffold(
      appBar: AppBar(title: const Text('Sell'), actions: const [_CartAction()]),
      body: BlocListener<ScanCubit, ScanState>(
        listener: _onScanState,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Fills the screen above the search field in portrait;
                  // keeps a usable minimum (and scrolls) in landscape.
                  final cameraHeight = math.max(
                    180.0,
                    constraints.maxHeight - 88,
                  );
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          children: [
                            SizedBox(
                              height: cameraHeight,
                              child: _ScannerView(
                                cameraOn: _cameraOn,
                                camera: (context) => camera(context, _onCode),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _search,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _submitSearch,
                              decoration: const InputDecoration(
                                hintText: 'Search product by name or code',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            PinnedBottomBar(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _enterBarcode,
                        child: const Text('Enter barcode'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BlocSelector<CartCubit, CartState, int>(
                        selector: (cart) => cart.total,
                        builder: (context, total) => FilledButton(
                          onPressed: () => context.push(RoutePaths.sellCart),
                          child: Text(
                            'Cart · ${Formatters.rwf(total)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cart icon with the number of products in the cart.
class _CartAction extends StatelessWidget {
  const _CartAction();

  @override
  Widget build(BuildContext context) {
    final count = context.select((CartCubit cubit) => cubit.state.items.length);
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => context.push(RoutePaths.sellCart),
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}

/// The live camera with corner brackets to aim at and a hint below them.
class _ScannerView extends StatelessWidget {
  const _ScannerView({required this.cameraOn, required this.camera});

  final ValueListenable<bool> cameraOn;
  final WidgetBuilder camera;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lookingUp = context.select(
      (ScanCubit cubit) => cubit.state is ScanLookingUp,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: colors.inverseSurface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: cameraOn,
              builder: (context, on, _) =>
                  on ? camera(context) : const SizedBox.shrink(),
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: _CornerFramePainter(color: colors.primaryContainer),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: IgnorePointer(
                child: Text(
                  'Point the camera at the product barcode',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onInverseSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (lookingUp)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(semanticsLabel: 'Looking up'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Four corner brackets around the area to aim at, with a scan line
/// across the middle.
class _CornerFramePainter extends CustomPainter {
  const _CornerFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final width = math.min(size.width * 0.7, 280.0);
    final height = math.min(width * 0.75, size.height * 0.6);
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero) - const Offset(0, 12),
      width: width,
      height: height,
    );
    final arm = math.min(32.0, height / 3);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    void corner(Offset at, double dx, double dy) {
      canvas
        ..drawLine(at, at + Offset(dx * arm, 0), paint)
        ..drawLine(at, at + Offset(0, dy * arm), paint);
    }

    corner(rect.topLeft, 1, 1);
    corner(rect.topRight, -1, 1);
    corner(rect.bottomLeft, 1, -1);
    corner(rect.bottomRight, -1, -1);
    canvas.drawLine(
      rect.centerLeft + const Offset(8, 0),
      rect.centerRight - const Offset(8, 0),
      paint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CornerFramePainter oldDelegate) =>
      color != oldDelegate.color;
}
