import 'package:flutter/material.dart';

import '../../domain/entities/pharmacy_account.dart';
import '../widgets/account_subpage.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

/// Settings > Staff and users: everyone with access to the pharmacy.
/// Only owners can open it; the Settings tab hides the row for pharmacists.
class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountSubpage(
      title: 'Staff and users',
      builder: (context, account) {
        // Also checked here in case the page is reached another way.
        if (!account.user.isOwner) {
          return const [
            Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Only the pharmacy owner can view staff and users.',
                textAlign: TextAlign.center,
              ),
            ),
          ];
        }

        final owners = account.staff.where((s) => s.isOwner).toList();
        final pharmacists = account.staff.where((s) => !s.isOwner).toList();

        return [
          if (owners.isNotEmpty)
            SettingsSection(
              label: 'OWNERS',
              rows: [for (final member in owners) _StaffRow(member: member)],
            ),
          if (pharmacists.isNotEmpty) ...[
            const SizedBox(height: 12),
            SettingsSection(
              label: 'PHARMACISTS',
              rows: [
                for (final member in pharmacists) _StaffRow(member: member),
              ],
            ),
          ],
        ];
      },
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context) =>
      SettingsRow(title: member.name, subtitle: member.email);
}
