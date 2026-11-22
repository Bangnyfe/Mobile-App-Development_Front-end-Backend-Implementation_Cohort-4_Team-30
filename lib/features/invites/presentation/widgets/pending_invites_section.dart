import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../settings/presentation/widgets/settings_row.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../domain/entities/pharmacy_invite.dart';
import '../cubit/pharmacy_invites_cubit.dart';
import 'invite_pharmacist_dialog.dart';

/// The owner's "Invite pharmacist" button and pending invites, shown on
/// Settings > Staff. Needs a [PharmacyInvitesCubit] above it.
class PendingInvitesSection extends StatelessWidget {
  const PendingInvitesSection({super.key});

  Future<void> _invite(BuildContext context) async {
    final cubit = context.read<PharmacyInvitesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final email = await InvitePharmacistDialog.show(
      context,
      onSend: cubit.send,
    );
    if (email == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Invite sent. Tell $email to sign in with this email to join.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        BlocBuilder<PharmacyInvitesCubit, PharmacyInvitesState>(
          builder: (context, state) => switch (state) {
            PharmacyInvitesLoading() => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            PharmacyInvitesFailure(:final message) => Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(message, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () =>
                        context.read<PharmacyInvitesCubit>().start(),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
            PharmacyInvitesLoaded(invites: []) => const SizedBox.shrink(),
            PharmacyInvitesLoaded(:final invites) => SettingsSection(
              label: 'PENDING INVITES',
              rows: [
                for (final invite in invites) _PendingInviteRow(invite: invite),
              ],
            ),
          },
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => _invite(context),
          icon: const Icon(Icons.person_add_alt_outlined),
          label: const Text('Invite pharmacist'),
        ),
      ],
    );
  }
}

class _PendingInviteRow extends StatelessWidget {
  const _PendingInviteRow({required this.invite});

  final PharmacyInvite invite;

  Future<void> _revoke(BuildContext context) async {
    final cubit = context.read<PharmacyInvitesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke invite?'),
        content: Text(
          '${invite.email} will no longer be able to join your pharmacy '
          'with this invite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await cubit.revoke(invite.email);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? 'Invite for ${invite.email} revoked.'),
          backgroundColor: error == null ? null : AppColors.danger,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = invite.createdAt;
    return SettingsRow(
      title: invite.email,
      subtitle: createdAt == null
          ? 'Pharmacist · waiting to join'
          : 'Pharmacist · invited ${Formatters.date(createdAt)}',
      trailing: TextButton(
        onPressed: () => _revoke(context),
        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
        child: const Text('Revoke'),
      ),
    );
  }
}
