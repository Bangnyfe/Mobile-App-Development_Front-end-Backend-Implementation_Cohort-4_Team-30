import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pinned_bottom_bar.dart';
import '../../domain/entities/sale_receipt.dart';
import '../cubit/cart_cubit.dart';

/// "Sale complete": the receipt for the sale just confirmed.
class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key, required this.receipt});

  final SaleReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final batches = receipt.batchesUpdated;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: colors.onPrimaryContainer,
                            semanticLabel: 'Done',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sale complete',
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stock updated in '
                        '${batches == 1 ? '1 batch' : '$batches batches'}',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ReceiptCard(receipt: receipt),
                    ],
                  ),
                ),
              ),
            ),
            PinnedBottomBar(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<CartCubit>().clear();
                          context.go(RoutePaths.sell);
                        },
                        child: const Text('New Sale'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go(RoutePaths.stock),
                        child: const Text('Inventory'),
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

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt});

  final SaleReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final secondary = textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final bold = textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    final servedBy = receipt.servedBy.isEmpty
        ? 'Thank you'
        : 'Served by ${receipt.servedBy} · Thank you';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (receipt.pharmacyName.isNotEmpty)
              Text(
                receipt.pharmacyName,
                textAlign: TextAlign.center,
                style: bold,
              ),
            if (receipt.pharmacyLocation.isNotEmpty)
              Text(
                receipt.pharmacyLocation,
                textAlign: TextAlign.center,
                style: secondary,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Receipt #${receipt.receiptNo}',
                    style: secondary,
                  ),
                ),
                Text(
                  '${Formatters.date(receipt.createdAt)} · '
                  '${Formatters.time(receipt.createdAt)}',
                  style: secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final line in receipt.lines) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.productName, style: bold),
                        Text(
                          '${line.quantity} × '
                          '${Formatters.amount(line.unitPrice)} · '
                          '${line.batchNumbers.join(', ')}',
                          style: secondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(Formatters.amount(line.lineTotal), style: bold),
                ],
              ),
              const SizedBox(height: 10),
            ],
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  Formatters.rwf(receipt.total),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (receipt.isCash) ...[
              _Row(
                label: 'Cash received',
                value: Formatters.amount(receipt.cashReceived),
                style: secondary,
              ),
              const SizedBox(height: 4),
              _Row(
                label: 'Change',
                value: Formatters.amount(receipt.change),
                style: secondary,
              ),
            ] else
              _Row(
                label: 'Paid by',
                value: receipt.paymentMethod,
                style: secondary,
              ),
            const SizedBox(height: 16),
            Text(servedBy, textAlign: TextAlign.center, style: secondary),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.style});

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
