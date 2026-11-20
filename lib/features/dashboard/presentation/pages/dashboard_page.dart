import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_list_row.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/greeting.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/stat_tile.dart';
import '../widgets/today_sales_card.dart';

/// Home tab: today's sales, stock health and recent transactions.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.clock = DateTime.now});

  /// Injected so tests get a fixed date and greeting.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) => switch (state) {
            DashboardLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            DashboardFailure(:final message) => _ErrorView(message: message),
            DashboardLoaded(:final summary) => _DashboardContent(
              summary: summary,
              now: clock(),
            ),
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary, required this.now});

  final DashboardSummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Centred and width-capped so the layout stays readable in landscape
    // and on large phones instead of stretching edge to edge.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _Header(
              dateLabel: Formatters.dayHeader(now),
              greeting:
                  '${greetingForHour(now.hour)}, ${summary.userFirstName}',
            ),
            const SizedBox(height: 16),
            TodaySalesCard(
              total: summary.todaySalesTotal,
              saleCount: summary.todaySalesCount,
              changeVsYesterday: summary.changeVsYesterday,
            ),
            const SizedBox(height: 12),
            _TileRow(
              left: StatTile(
                label: 'Current stock',
                value: Formatters.amount(summary.productCount),
                caption:
                    'products · ${Formatters.amount(summary.unitsInStock)} units',
              ),
              right: StatTile(
                label: 'Low stock',
                value: Formatters.amount(summary.lowStockCount),
                caption: 'below threshold',
              ),
            ),
            const SizedBox(height: 12),
            _TileRow(
              left: StatTile(
                label: 'Expiring in ${summary.expiringWindowDays} days',
                value: Formatters.amount(summary.expiringBatchCount),
                caption:
                    'batches · ${Formatters.rwf(summary.expiringCostValue)} at cost',
              ),
              right: StatTile(
                label: 'Expired',
                value: Formatters.amount(summary.expiredBatchCount),
                caption: 'batches to pull from shelf',
                isAlert: summary.expiredBatchCount > 0,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go(RoutePaths.sell),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Quick scan'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'RECENT TRANSACTIONS',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(RoutePaths.salesHistory),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _RecentSalesList(summary: summary),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.dateLabel, required this.greeting});

  final String dateLabel;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                greeting,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // Disabled until the Notifications screen is added; the unread
        // badge comes from NotificationsCubit.
        IconButton(
          onPressed: null,
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    );
  }
}

/// Two tiles side by side with equal heights.
class _TileRow extends StatelessWidget {
  const _TileRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _RecentSalesList extends StatelessWidget {
  const _RecentSalesList({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.recentSales.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No sales yet today.'),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, sale) in summary.recentSales.indexed) ...[
            if (index > 0) const Divider(indent: 62),
            AppListRow(
              icon: Icons.receipt_long_outlined,
              title: 'Sale #${sale.receiptNo}',
              subtitle:
                  '${Formatters.time(sale.createdAt)} · '
                  '${Formatters.itemCount(sale.itemCount)} · '
                  '${sale.paymentMethod}',
              trailing: Formatters.amount(sale.total),
              onTap: () => context.push(RoutePaths.saleDetails(sale.saleId)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.read<DashboardCubit>().start(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
