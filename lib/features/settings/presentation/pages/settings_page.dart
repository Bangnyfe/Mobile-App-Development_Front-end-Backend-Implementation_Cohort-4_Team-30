import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/pharmacy_account.dart';
import '../cubit/account_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/number_setting_dialog.dart';
import '../widgets/pharmacy_header_card.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

/// Settings tab: the pharmacy, alert preferences and logging out.
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
                  const _AccountSections(),
                  const SizedBox(height: 12),
                  const _AlertsSection(),
                  const SizedBox(height: 32),
                  const _LogOutButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The header card and the Pharmacy section, which need the account.
class _AccountSections extends StatelessWidget {
  const _AccountSections();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountCubit>().state;

    return switch (state) {
      AccountLoading() => const Card(
        child: SizedBox(
          height: 88,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      AccountFailure(:final message) => Card(
        child: SettingsRow(
          title: message,
          trailing: TextButton(
            onPressed: () => context.read<AccountCubit>().load(),
            child: const Text('Try again'),
          ),
        ),
      ),
      AccountLoaded(:final account) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PharmacyHeaderCard(account: account),
          const SizedBox(height: 12),
          _PharmacySection(account: account),
        ],
      ),
    };
  }
}

class _PharmacySection extends StatelessWidget {
  const _PharmacySection({required this.account});

  final PharmacyAccount account;

  @override
  Widget build(BuildContext context) {
    final staffCount = account.staff.length;

    return SettingsSection(
      label: 'PHARMACY',
      rows: [
        SettingsRow(
          title: 'Pharmacy profile',
          showChevron: true,
          onTap: () => context.go(RoutePaths.pharmacyProfile),
        ),
        // Only owners manage users.
        if (account.user.isOwner)
          SettingsRow(
            title: 'Staff and users',
            detail: staffCount == 1 ? '1 person' : '$staffCount people',
            showChevron: true,
            onTap: () => context.go(RoutePaths.staff),
          ),
        SettingsRow(
          title: 'Product categories',
          detail: '${account.categories.length}',
          showChevron: true,
          onTap: () => context.go(RoutePaths.categories),
        ),
      ],
    );
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.select(
      (SettingsCubit cubit) => cubit.state.settings,
    );
    final cubit = context.read<SettingsCubit>();

    return SettingsSection(
      label: 'ALERTS',
      rows: [
        SettingsRow(
          title: 'Low stock threshold',
          subtitle: 'Default for new products',
          value: '${settings.lowStockThreshold} units',
          onTap: () async {
            final value = await showNumberSettingDialog(
              context,
              title: 'Low stock threshold',
              unit: 'units',
              initialValue: settings.lowStockThreshold,
              min: AppSettings.minLowStockThreshold,
              max: AppSettings.maxLowStockThreshold,
            );
            if (value != null) await cubit.updateLowStockThreshold(value);
          },
        ),
        SettingsRow(
          title: 'Expiry alert period',
          subtitle: 'Warn before a batch expires',
          value: '${settings.expiryAlertDays} days',
          onTap: () async {
            final value = await showNumberSettingDialog(
              context,
              title: 'Expiry alert period',
              unit: 'days',
              initialValue: settings.expiryAlertDays,
              min: AppSettings.minExpiryAlertDays,
              max: AppSettings.maxExpiryAlertDays,
            );
            if (value != null) await cubit.updateExpiryAlertDays(value);
          },
        ),
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
    );
  }
}

class _LogOutButton extends StatelessWidget {
  const _LogOutButton();

  Future<void> _confirmAndLogOut(BuildContext context) async {
    final accountCubit = context.read<AccountCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          "You'll need to sign in again to use the app on this phone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    // Once auth is merged, signing out sends the router to the login
    // screen, so nothing else is needed here.
    if (confirmed ?? false) await accountCubit.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmAndLogOut(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: const BorderSide(color: AppColors.danger),
        minimumSize: const Size.fromHeight(52),
      ),
      icon: const Icon(Icons.logout),
      label: const Text('Log out'),
    );
  }
}
