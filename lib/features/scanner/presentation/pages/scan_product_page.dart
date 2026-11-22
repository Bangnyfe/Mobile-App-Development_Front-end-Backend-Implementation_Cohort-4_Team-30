import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../inventory/presentation/widgets/fefo_batch_indicator.dart';
import '../../../pos/domain/entities/pos_batch.dart';
import '../cubit/scan_cubit.dart';
import 'scanner_page.dart';

/// The Sell tab's starting point: scan a pack and see the product found,
/// its price and its batches (sell-first and expired marked).
///
/// The cart and checkout screens build on this: a found product is ready
/// for `CartCubit.addItem`.
class ScanProductPage extends StatelessWidget {
  const ScanProductPage({super.key, this.clock = DateTime.now});

  /// For tests; the app uses the real time.
  final DateTime Function() clock;

  static Future<void> _scan(BuildContext context) async {
    final cubit = context.read<ScanCubit>();
    final code = await ScannerPage.open(context, title: 'Scan to sell');
    if (code != null) await cubit.lookUp(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sell')),
      body: BlocBuilder<ScanCubit, ScanState>(
        builder: (context, state) => switch (state) {
          ScanIdle() => _Message(
            icon: Icons.qr_code_scanner,
            title: 'Scan a product to sell',
            body:
                'Scan the barcode on the pack, or type it, to see the '
                'product, its price and which batch to sell first.',
            action: 'Scan barcode',
            onAction: () => _scan(context),
          ),
          ScanLookingUp(:final code) => _Message(
            icon: Icons.search,
            title: 'Looking up ${code.gtin}…',
            body: '',
            busy: true,
          ),
          ScanNotFound(:final code) => _Message(
            icon: Icons.search_off,
            title: 'Product not found',
            body:
                'No product in your pharmacy has the barcode ${code.gtin}. '
                'Check the pack, or register the product first.',
            action: 'Scan again',
            onAction: () => _scan(context),
          ),
          ScanFailure(:final message) => _Message(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't look it up",
            body: message,
            action: 'Try again',
            onAction: context.read<ScanCubit>().retry,
            secondaryAction: 'Scan again',
            onSecondaryAction: () => _scan(context),
          ),
          ScanFound() => _FoundView(
            state: state,
            today: clock(),
            onScanAgain: () => _scan(context),
          ),
        },
      ),
    );
  }
}

class _FoundView extends StatelessWidget {
  const _FoundView({
    required this.state,
    required this.today,
    required this.onScanAgain,
  });

  final ScanFound state;
  final DateTime today;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final found = state.found;
    final product = found.product;
    final scannedBatch = state.scannedBatch;
    final sellable = found.sellableUnitsOn(today);
    final scannedExpiry = state.code.expiryDate;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              // Width-capped so it stays readable in landscape.
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text('Product found', style: textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: textTheme.titleLarge),
                          if (found.details.isNotEmpty)
                            Text(found.details, style: textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Barcode ${product.barcode}',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  Formatters.rwf(product.sellingPrice),
                                  style: textTheme.headlineSmall,
                                ),
                              ),
                              Text(
                                '${Formatters.unitCount(sellable)} to sell',
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.code.batchNumber != null) ...[
                    const SizedBox(height: 12),
                    _ScannedBatchNote(
                      batchNumber: state.code.batchNumber!,
                      expiry: scannedExpiry,
                      batch: scannedBatch,
                      today: today,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('BATCHES', style: textTheme.labelMedium),
                  const SizedBox(height: 8),
                  if (found.batches.isEmpty)
                    const Text('No batches in stock.')
                  else
                    for (final batch in found.batches)
                      _BatchRow(
                        batch: batch,
                        batches: found.batches,
                        today: today,
                        scanned: batch.id == scannedBatch?.id,
                      ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onScanAgain,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan another product'),
            ),
          ),
        ),
      ],
    );
  }
}

/// What the DataMatrix said about this pack's batch.
class _ScannedBatchNote extends StatelessWidget {
  const _ScannedBatchNote({
    required this.batchNumber,
    required this.expiry,
    required this.batch,
    required this.today,
  });

  final String batchNumber;
  final DateTime? expiry;
  final PosBatch? batch;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final expired = batch?.isExpiredOn(today) ?? false;
    final expiry = this.expiry;
    final text = StringBuffer('This pack is from batch $batchNumber');
    if (expiry != null) text.write(', expiring ${Formatters.date(expiry)}');
    text.write('.');
    if (batch == null) {
      text.write(" That batch isn't in your stock records.");
    } else if (expired) {
      text.write(' It has expired: do not sell it.');
    }

    final warn = batch == null || expired;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warn ? AppColors.dangerContainer : AppColors.infoContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warn ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
            color: warn ? AppColors.danger : AppColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text.toString())),
        ],
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({
    required this.batch,
    required this.batches,
    required this.today,
    required this.scanned,
  });

  final PosBatch batch;
  final List<PosBatch> batches;
  final DateTime today;
  final bool scanned;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: scanned
          ? RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.info, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        title: Text('Batch ${batch.batchNumber}'),
        subtitle: Text(
          'Expires ${Formatters.date(batch.expiryDate)} · '
          '${Formatters.unitCount(batch.quantity)}',
        ),
        trailing: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (scanned)
              const StatusChip(label: 'Scanned', tone: StatusTone.info),
            FefoBatchIndicator(batch: batch, batches: batches, today: today),
          ],
        ),
      ),
    );
  }
}

/// An icon, a title and a short explanation, with up to two buttons.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
    this.secondaryAction,
    this.onSecondaryAction,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  final String? secondaryAction;
  final VoidCallback? onSecondaryAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const CircularProgressIndicator()
              else
                Icon(icon, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(body, textAlign: TextAlign.center),
              ],
              if (action != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(action!),
                ),
              ],
              if (secondaryAction != null)
                TextButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondaryAction!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
