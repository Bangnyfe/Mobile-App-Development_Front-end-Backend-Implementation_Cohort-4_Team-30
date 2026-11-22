import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/report_period.dart';
import '../../domain/stock_report.dart';
import '../cubit/stock_reports_cubit.dart';
import '../report_export.dart';
import '../widgets/report_scaffold.dart';
import '../widgets/report_widgets.dart';

/// Expiry and waste report: expired stock
/// removed in the period, expired stock still on the shelf, a monthly
/// chart, and a Remove stock button for each expired batch.
class ExpiryWasteReportPage extends StatelessWidget {
  const ExpiryWasteReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScaffold(
      title: 'Expiry and waste',
      builder: (context, state) {
        final cubit = context.read<StockReportsCubit>();
        final removed = state.expiredRemovedTotals;
        final onShelf = state.expiredStillOnShelf;

        return [
          Wrap(
            spacing: 8,
            children: [
              for (final period in ReportPeriod.values)
                ChoiceChip(
                  label: Text(period.label),
                  selected: state.period == period,
                  onSelected: (_) => cubit.selectPeriod(period),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ReportStatCard(
                  title: 'Expired, removed',
                  value: Formatters.rwf(removed.value),
                  caption: removed.count == 1
                      ? '1 batch removed'
                      : '${removed.count} batches removed',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ReportStatCard(
                  title: 'Expired on shelf',
                  value: Formatters.rwf(state.expiredOnShelfValue),
                  caption: onShelf.isEmpty
                      ? 'Nothing to remove'
                      : 'Needs to be removed',
                  danger: onShelf.isNotEmpty,
                ),
              ),
            ],
          ),
          const ReportSectionHeader(
            title: 'Expired stock removed by month, at cost',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: MonthBarChart(totals: state.expiredByMonth),
            ),
          ),
          ReportSectionHeader(
            title: 'Expired, still on the shelf',
            trailing: '${onShelf.length}',
          ),
          if (onShelf.isEmpty)
            const Card(
              child: ReportEmptyMessage('Nothing expired is on the shelf.'),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (index, line) in onShelf.indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    _ExpiredBatchRow(
                      line: line,
                      onRemove: () async {
                        await context.push(
                          RoutePaths.removeExpiredBatch(
                            productId: line.productId,
                            batchId: line.batchId,
                          ),
                        );
                        // Back from Remove stock: show the new totals.
                        await cubit.load();
                      },
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go(RoutePaths.inventoryReport),
              child: const Text('See all stock removals'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => copyReport(context, expiryWasteReportText(state)),
            icon: const Icon(Icons.ios_share),
            label: const Text('Export report'),
          ),
        ];
      },
    );
  }
}

class _ExpiredBatchRow extends StatelessWidget {
  const _ExpiredBatchRow({required this.line, required this.onRemove});

  final ExpiredBatchLine line;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                Formatters.rwf(line.value),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Batch ${line.batchNumber} · ${Formatters.unitCount(line.units)} · '
            'expired ${Formatters.date(line.expiryDate)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.onPrimary,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Remove stock'),
          ),
        ],
      ),
    );
  }
}
