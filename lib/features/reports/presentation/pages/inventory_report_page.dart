import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../stock_removal/domain/entities/stock_removal.dart';
import '../report_export.dart';
import '../widgets/report_scaffold.dart';
import '../widgets/report_widgets.dart';

/// Inventory report: stock value at cost, what
/// was removed this month, and every stock removal with its reason.
class InventoryReportPage extends StatelessWidget {
  const InventoryReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScaffold(
      title: 'Inventory report',
      builder: (context, state) {
        final month = state.thisMonthTotals;
        return [
          ReportStatCard(
            title: 'Stock on hand at cost',
            value: Formatters.rwf(state.stockValue),
            caption: state.productCount == 1
                ? '1 product in stock'
                : '${state.productCount} products in stock',
          ),
          const SizedBox(height: 12),
          ReportStatCard(
            title: 'Removed this month',
            value:
                '${Formatters.unitCount(month.units)} · '
                '${Formatters.rwf(month.value)}',
            caption: month.count == 1 ? '1 removal' : '${month.count} removals',
            danger: true,
          ),
          ReportSectionHeader(
            title: 'Stock removals · last 12 months',
            trailing: '${state.removals.length}',
          ),
          if (state.removals.isEmpty)
            const Card(
              child: ReportEmptyMessage('No stock has been removed yet.'),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (index, removal) in state.removals.indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    _RemovalRow(removal),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => copyReport(context, inventoryReportText(state)),
            icon: const Icon(Icons.ios_share),
            label: const Text('Export report'),
          ),
        ];
      },
    );
  }
}

class _RemovalRow extends StatelessWidget {
  const _RemovalRow(this.removal);

  final StockRemoval removal;

  @override
  Widget build(BuildContext context) {
    final details = [
      'Batch ${removal.batchNumber}',
      Formatters.unitCount(removal.quantity),
      Formatters.date(removal.createdAt),
      if (removal.removedByName.isNotEmpty) removal.removedByName,
    ].join(' · ');

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    removal.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (removal.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      removal.note,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.rwf(removal.costValue),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                ReasonChip(removal.reason),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
