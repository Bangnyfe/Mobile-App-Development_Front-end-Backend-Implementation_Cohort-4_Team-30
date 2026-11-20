import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/expiry_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/stock_alert.dart';
import '../cubit/notifications_cubit.dart';

/// Expired, expiring and low-stock alerts, most urgent first.
///
/// New alerts are marked while the page is open and count as seen once the
/// user leaves, so the bell's badge clears without the "New" marks
/// disappearing the moment the page opens.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.clock = DateTime.now});

  /// Injected so tests get fixed "days left" labels.
  final DateTime Function() clock;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Kept here because context can't be used in dispose.
  late final NotificationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<NotificationsCubit>();
  }

  @override
  void dispose() {
    _cubit.markAllSeen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) => switch (state) {
            NotificationsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            NotificationsFailure(:final message) => _ErrorView(
              message: message,
            ),
            NotificationsLoaded(alerts: []) => const _AllClearView(),
            NotificationsLoaded() => _AlertList(
              state: state,
              today: widget.clock(),
            ),
          },
        ),
      ),
    );
  }
}

class _AlertList extends StatelessWidget {
  const _AlertList({required this.state, required this.today});

  final NotificationsLoaded state;
  final DateTime today;

  static const _sectionTitles = {
    StockAlertType.expired: 'Expired',
    StockAlertType.expiringSoon: 'Expiring soon',
    StockAlertType.lowStock: 'Low stock',
  };

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
            for (final type in StockAlertType.values)
              if (state.alerts.where((a) => a.type == type).toList()
                  case final alerts when alerts.isNotEmpty) ...[
                _SectionHeader(
                  title: _sectionTitles[type]!,
                  count: alerts.length,
                ),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (index, alert) in alerts.indexed) ...[
                        if (index > 0) const Divider(indent: 62),
                        _AlertRow(
                          alert: alert,
                          isNew: state.isNew(alert),
                          today: today,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Expanded(child: Text(title.toUpperCase(), style: style)),
          Text('$count', style: style),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.alert,
    required this.isNew,
    required this.today,
  });

  final StockAlert alert;
  final bool isNew;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chip = _chip();

    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: chip.tone.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 20, color: chip.tone.foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.productName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              chip,
              if (isNew) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: 'New',
                  child: Container(
                    key: const ValueKey('new-alert-dot'),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (alert.type) {
    StockAlertType.expired => Icons.event_busy_outlined,
    StockAlertType.expiringSoon => Icons.schedule_outlined,
    StockAlertType.lowStock => Icons.inventory_2_outlined,
  };

  String get _subtitle => switch (alert.type) {
    StockAlertType.expired => [
      'Batch ${alert.batchNumber}',
      Formatters.unitCount(alert.quantity),
      'expired ${Formatters.date(alert.expiryDate!)}',
    ].join(' · '),
    StockAlertType.expiringSoon => [
      'Batch ${alert.batchNumber}',
      Formatters.unitCount(alert.quantity),
      'expires ${Formatters.date(alert.expiryDate!)}',
    ].join(' · '),
    StockAlertType.lowStock when alert.isOutOfStock =>
      'No stock left · reorder at ${alert.reorderLevel}',
    StockAlertType.lowStock =>
      '${Formatters.unitCount(alert.quantity)} left · '
          'reorder at ${alert.reorderLevel}',
  };

  StatusChip _chip() {
    switch (alert.type) {
      case StockAlertType.expired:
        return const StatusChip(label: 'Expired', tone: StatusTone.danger);
      case StockAlertType.expiringSoon:
        final days = daysUntilExpiry(alert.expiryDate!, today: today);
        return StatusChip(
          label: switch (days) {
            <= 0 => 'Expires today',
            1 => '1 day',
            _ => '$days days',
          },
          tone: StatusTone.warning,
        );
      case StockAlertType.lowStock when alert.isOutOfStock:
        return const StatusChip(label: 'Out of stock', tone: StatusTone.danger);
      case StockAlertType.lowStock:
        return const StatusChip.lowStock();
    }
  }
}

class _AllClearView extends StatelessWidget {
  const _AllClearView();

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
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.success,
            ),
            const SizedBox(height: 12),
            Text('All clear', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'No expired, expiring or low-stock products right now.',
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
              onPressed: () => context.read<NotificationsCubit>().start(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
