import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_list_row.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sales_day.dart';
import '../../domain/repositories/sales_repository.dart';
import '../cubit/sales_history_cubit.dart';

/// Every recent sale, grouped by day with each day's total.
class SalesHistoryPage extends StatelessWidget {
  const SalesHistoryPage({super.key, this.clock = DateTime.now});

  /// Injected so tests get fixed "Today" and "Yesterday" headings.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales history')),
      body: SafeArea(
        child: BlocBuilder<SalesHistoryCubit, SalesHistoryState>(
          builder: (context, state) => switch (state) {
            SalesHistoryLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SalesHistoryFailure(:final message) => _ErrorView(message: message),
            SalesHistoryLoaded(days: []) => const _EmptyView(),
            SalesHistoryLoaded(:final days, :final isAtLimit) => _SalesList(
              days: days,
              isAtLimit: isAtLimit,
              now: clock(),
            ),
          },
        ),
      ),
    );
  }
}

class _SalesList extends StatelessWidget {
  const _SalesList({
    required this.days,
    required this.isAtLimit,
    required this.now,
  });

  final List<SalesDay> days;
  final bool isAtLimit;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    // Centred and width-capped like the other screens, so rows stay
    // readable in landscape.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final day in days) ...[
              _DayHeader(day: day, label: _dayLabel(day.date, now)),
              _DayCard(day: day),
              const SizedBox(height: 16),
            ],
            if (isAtLimit)
              Text(
                'Showing the latest ${SalesRepository.defaultLimit} sales.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  static String _dayLabel(DateTime day, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    return Formatters.dayHeader(day);
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.label});

  final SalesDay day;
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );
    final count = day.saleCount == 1 ? '1 sale' : '${day.saleCount} sales';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Expanded(child: Text(label.toUpperCase(), style: style)),
          Text('$count · ${Formatters.rwf(day.total)}', style: style),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final SalesDay day;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, sale) in day.sales.indexed) ...[
            if (index > 0) const Divider(indent: 62),
            _SaleRow(sale: sale),
          ],
        ],
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return AppListRow(
      icon: Icons.receipt_long_outlined,
      title: 'Sale #${sale.receiptNo}',
      // The seller goes last, so it's what gets cut off on narrow screens.
      subtitle: [
        Formatters.time(sale.createdAt),
        Formatters.itemCount(sale.itemCount),
        sale.paymentMethod,
        sale.sellerName,
      ].join(' · '),
      trailing: Formatters.amount(sale.total),
      // push, not go, so back returns to wherever the history was opened.
      onTap: () => context.push(RoutePaths.saleDetails(sale.id)),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text('No sales yet', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Sales show up here as soon as they are checked out.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
              onPressed: () => context.read<SalesHistoryCubit>().start(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
