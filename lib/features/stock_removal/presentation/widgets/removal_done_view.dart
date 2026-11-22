import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../cubit/remove_stock_cubit.dart';
import 'bottom_action_bar.dart';

/// Confirmation after saving: what was
/// removed, the stock change and the value written off.
class RemovalDoneView extends StatelessWidget {
  const RemovalDoneView({super.key, required this.state});

  final RemoveStockState state;

  @override
  Widget build(BuildContext context) {
    final removal = state.result!;
    final unitsAfter = state.productUnits;
    final unitsBefore = unitsAfter + removal.quantity;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 16),
              const Center(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.successContainer,
                  child: Icon(Icons.check, size: 36, color: AppColors.success),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${Formatters.unitCount(removal.quantity)} removed',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Recorded in the inventory report',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _DetailRow('Product', removal.productName),
                    _DetailRow('Batch', removal.batchNumber),
                    _DetailRow(
                      'Reason',
                      removal.note.isEmpty
                          ? removal.reason.label
                          : '${removal.reason.label} · ${removal.note}',
                    ),
                    _DetailRow('Stock change', '$unitsBefore → $unitsAfter'),
                    _DetailRow(
                      'Written off (cost)',
                      Formatters.rwf(removal.costValue),
                    ),
                    _DetailRow('Removed by', removal.removedByName),
                    _DetailRow(
                      'Date and time',
                      '${Formatters.date(removal.createdAt)}, '
                          '${Formatters.time(removal.createdAt)}',
                      last: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        BottomActionBar(
          children: [
            OutlinedButton(
              onPressed: () => context.go(RoutePaths.inventoryReport),
              child: const Text('View in inventory report'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => context.go(RoutePaths.stock),
              child: const Text('Back to inventory'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
