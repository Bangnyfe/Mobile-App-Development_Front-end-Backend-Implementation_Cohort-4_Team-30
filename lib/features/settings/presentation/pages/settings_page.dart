import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/settings_row.dart';

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
        body: SafeArea(
          // Centred and width-capped like the dashboard, so it stays
          // readable in landscape.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  const _SectionLabel('ALERTS'),
                  const _AlertsCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard();

  @override
  Widget build(BuildContext context) {
    final settings = context.select(
      (SettingsCubit cubit) => cubit.state.settings,
    );
    final cubit = context.read<SettingsCubit>();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SettingsRow(
            title: 'Low stock threshold',
            subtitle: 'Default for new products',
            value: '${settings.lowStockThreshold} units',
          ),
          const Divider(indent: 16, endIndent: 16),
          SettingsRow(
            title: 'Expiry alert period',
            subtitle: 'Warn before a batch expires',
            value: '${settings.expiryAlertDays} days',
          ),
          const Divider(indent: 16, endIndent: 16),
          // MergeSemantics reads the title and the switch as one control,
          // and tapping anywhere on the row flips it.
          MergeSemantics(
            child: SettingsRow(
              title: 'Push notifications',
              onTap: () => cubit.setPushNotificationsEnabled(
                !settings.pushNotificationsEnabled,
              ),
              trailing: Switch(
                value: settings.pushNotificationsEnabled,
                onChanged: cubit.setPushNotificationsEnabled,
              ),
            ),
          ),
        ],
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
