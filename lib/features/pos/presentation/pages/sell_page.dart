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
import '../cubit/product_search_cubit.dart';

/// The Sell tab: scan a pack with the camera, type its barcode, or search
/// the pharmacy's products by name, to open Product found. Shows the cart's
/// size and total.
class SellPage extends StatefulWidget {
  const SellPage({super.key, this.clock = DateTime.now});

  /// For tests; the app uses the real time.
  final DateTime Function() clock;

  static String noMatchMessage(String query) => 'No product matches "$query"';

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

  /// Enter in the search field: a full barcode is looked up like a scan;
  /// a name opens the product when only one matches.
  void _submitSearch(String text) {
    final search = context.read<ProductSearchCubit>();
    final code = Gs1Parser.parse(text.trim());
    if (code != null) {
      _clearSearch();
      context.read<ScanCubit>().lookUp(code);
      return;
    }
    final results = search.state.results;
    if (results.length == 1) {
      search.open(results.single.product.id);
    } else if (results.isEmpty && search.state.status == SearchStatus.ready) {
      _showMessage(SellPage.noMatchMessage(search.state.query));
    }
  }

  void _clearSearch() {
    _search.clear();
    context.read<ProductSearchCubit>().clear();
  }

  void _onSearchState(BuildContext context, ProductSearchState state) {
    final found = state.opened;
    if (found != null) {
      FocusScope.of(context).unfocus();
      _clearSearch();
      context.push(RoutePaths.sellProduct, extra: found);
      return;
    }
    final message = state.message;
    if (message != null && state.status != SearchStatus.failure) {
      _showMessage(message);
    }
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
      body: MultiBlocListener(
        listeners: [
          BlocListener<ScanCubit, ScanState>(listener: _onScanState),
          BlocListener<ProductSearchCubit, ProductSearchState>(
            listenWhen: (previous, current) =>
                current.opened != previous.opened ||
                current.message != previous.message,
            listener: _onSearchState,
          ),
        ],
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
                              // While searching, the results take the
                              // camera's place and the camera is off.
                              child: _searching(context)
                                  ? const _SearchResults()
                                  : _ScannerView(
                                      cameraOn: _cameraOn,
                                      camera: (context) =>
                                          camera(context, _onCode),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: const ValueKey('sell-search'),
                              controller: _search,
                              textInputAction: TextInputAction.search,
                              onChanged: context
                                  .read<ProductSearchCubit>()
                                  .search,
                              onSubmitted: _submitSearch,
                              decoration: InputDecoration(
                                hintText: 'Search product by name or code',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon:
                                    ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _search,
                                      builder: (context, value, _) =>
                                          value.text.isEmpty
                                          ? const SizedBox.shrink()
                                          : IconButton(
                                              tooltip: 'Clear search',
                                              onPressed: _clearSearch,
                                              icon: const Icon(Icons.close),
                                            ),
                                    ),
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

bool _searching(BuildContext context) =>
    context.select((ProductSearchCubit cubit) => cubit.state.isSearching);

/// The products matching what's typed in the search field.
class _SearchResults extends StatelessWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final cubit = context.read<ProductSearchCubit>();
    final state = context.watch<ProductSearchCubit>().state;

    final Widget body;
    if (state.status == SearchStatus.failure) {
      body = _SearchMessage(
        icon: Icons.cloud_off_outlined,
        text: state.message ?? ProductSearchCubit.loadFailedMessage,
        action: TextButton(
          onPressed: () => cubit.search(state.query),
          child: const Text('Try again'),
        ),
      );
    } else if (state.results.isEmpty) {
      body = state.status == SearchStatus.ready
          ? _SearchMessage(
              icon: Icons.search_off,
              text:
                  '${SellPage.noMatchMessage(state.query)}. Check the '
                  'spelling, or scan the barcode.',
            )
          : const Center(child: CircularProgressIndicator());
    } else {
      body = ListView.separated(
        itemCount: state.results.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = state.results[index];
          final product = item.product;
          final barcode = product.barcode.isEmpty
              ? 'No barcode'
              : 'Barcode ${product.barcode}';
          return ListTile(
            key: ValueKey('search-result-${product.id}'),
            minTileHeight: 56,
            enabled: !state.opening,
            onTap: () => cubit.open(product.id),
            title: Text(
              product.name,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              [item.details, barcode].where((s) => s.isNotEmpty).join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: Text(
              Formatters.rwf(product.sellingPrice),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: body),
          if (state.opening)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(semanticsLabel: 'Opening'),
            ),
        ],
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

/// Cart icon with the number of units in the cart: the same count as the
/// Sell tab's badge in the bottom bar, so the two never disagree.
class _CartAction extends StatelessWidget {
  const _CartAction();

  @override
  Widget build(BuildContext context) {
    final count = context.select((CartCubit cubit) => cubit.state.itemCount);
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
