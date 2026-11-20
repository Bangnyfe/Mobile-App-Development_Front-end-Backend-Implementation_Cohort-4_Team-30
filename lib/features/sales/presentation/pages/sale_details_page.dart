import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/sale.dart';
import '../cubit/sale_details_cubit.dart';

/// One sale: when and by whom, what was sold, and how it was paid.
class SaleDetailsPage extends StatelessWidget {
  const SaleDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sale details')),
      body: SafeArea(
        child: BlocBuilder<SaleDetailsCubit, SaleDetailsState>(
          builder: (context, state) => switch (state) {
            SaleDetailsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SaleDetailsNotFound() => const _MessageView(
              message: "This sale couldn't be found.",
            ),
            SaleDetailsFailure(:final message) => _MessageView(
              message: message,
              onRetry: () => context.read<SaleDetailsCubit>().load(),
            ),
            SaleDetailsLoaded(:final sale) => _SaleContent(sale: sale),
          },
        ),
      ),
    );
  }
}

class _SaleContent extends StatelessWidget {
  const _SaleContent({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final items = _combine(sale.lines);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sale #${sale.receiptNo}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.dayHeader(sale.createdAt)} · '
                      '${Formatters.time(sale.createdAt)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Formatters.rwf(sale.total),
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 24),
                    _DetailRow(label: 'Sold by', value: sale.sellerName),
                    _DetailRow(label: 'Payment', value: sale.paymentMethod),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                'ITEMS · ${Formatters.itemCount(sale.itemCount).toUpperCase()}',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final (index, item) in items.indexed) ...[
                      if (index > 0) const Divider(indent: 16),
                      _ItemRow(item: item),
                    ],
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        children: [
                          _DetailRow(
                            label: 'Total',
                            value: Formatters.rwf(sale.total),
                            isBold: true,
                          ),
                          if (sale.isCash) ...[
                            _DetailRow(
                              label: 'Cash received',
                              value: Formatters.rwf(sale.cashReceived),
                            ),
                            _DetailRow(
                              label: 'Change',
                              value: Formatters.rwf(sale.change),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Merges lines of the same product and price. FEFO can split one
  /// product across batches, but the customer bought one item.
  static List<SaleLine> _combine(List<SaleLine> lines) {
    final combined = <(String, int), SaleLine>{};
    for (final line in lines) {
      final key = (line.productId, line.unitPrice);
      final existing = combined[key];
      combined[key] = existing == null
          ? line
          : SaleLine(
              productId: line.productId,
              batchId: existing.batchId,
              productName: existing.productName,
              quantity: existing.quantity + line.quantity,
              unitPrice: line.unitPrice,
            );
    }
    return combined.values.toList();
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final SaleLine item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.quantity} × ${Formatters.amount(item.unitPrice)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              Formatters.amount(item.lineTotal),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final weight = isBold ? FontWeight.w700 : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: isBold ? null : AppColors.textSecondary,
                fontWeight: weight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(fontWeight: weight),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
