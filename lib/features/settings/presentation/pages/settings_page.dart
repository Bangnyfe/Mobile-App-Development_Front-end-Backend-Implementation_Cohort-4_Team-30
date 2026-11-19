import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_list_row.dart';
import '../cubit/settings_cubit.dart';

/// Settings tab: alert thresholds and notification preferences.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          current.errorCount != previous.errorCount && current.error != null,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.error!))),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: SafeArea(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final settings = state.settings;

              // Centred and width-capped like the dashboard, so it stays
              // readable in landscape.
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      const _SectionLabel('ALERTS'),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            AppListRow(
                              icon: Icons.inventory_2_outlined,
                              title: 'Low-stock threshold',
                              subtitle: 'Flag products at or below this',
                              trailing: '${settings.lowStockThreshold} units',
                            ),
                            const Divider(indent: 62),
                            AppListRow(
                              icon: Icons.event_busy_outlined,
                              title: 'Expiry alert period',
                              subtitle: 'Warn before batches expire',
                              trailing: '${settings.expiryAlertDays} days',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('NOTIFICATIONS'),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: AppListRow(
                          icon: Icons.notifications_none,
                          title: 'Push notifications',
                          subtitle: 'Low-stock and expiry alerts',
                          trailing: settings.pushNotificationsEnabled
                              ? 'On'
                              : 'Off',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
