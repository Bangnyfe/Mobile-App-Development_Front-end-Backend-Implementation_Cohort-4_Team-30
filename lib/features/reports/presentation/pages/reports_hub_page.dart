import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';

/// Reports tab: the starting point for every report in the app.
class ReportsHubPage extends StatelessWidget {
  const ReportsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        // Centred and width-capped like Settings, so it stays readable in
        // landscape.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  'Reports',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'See what was sold, what is in stock and what was lost.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const _ReportSection(
                  label: 'SALES',
                  rows: [
                    _ReportRow(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sales history',
                      subtitle: 'Every sale, grouped by day with daily totals',
                      path: RoutePaths.reportsSalesHistory,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _ReportSection(
                  label: 'STOCK',
                  rows: [
                    _ReportRow(
                      icon: Icons.inventory_2_outlined,
                      title: 'Inventory report',
                      subtitle: 'Stock on hand, low stock and value at cost',
                      path: RoutePaths.inventoryReport,
                    ),
                    _ReportRow(
                      icon: Icons.event_busy_outlined,
                      title: 'Expiry & waste report',
                      subtitle: 'Batches expiring soon and stock removed',
                      path: RoutePaths.expiryWasteReport,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled card of report rows, with dividers between them.
class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.label, required this.rows});

  final String label;
  final List<_ReportRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, row) in rows.indexed) ...[
                if (index > 0) const Divider(indent: 64, endIndent: 16),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One report: an icon, its name and what it shows, and a chevron.
class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.path,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String path;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => context.go(path),
      child: ConstrainedBox(
        // Keeps every row at least a 48dp tap target.
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
