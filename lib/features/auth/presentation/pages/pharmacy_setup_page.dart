import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../invites/domain/entities/pharmacy_invite.dart';
import '../../../invites/presentation/cubit/pharmacy_choice_cubit.dart';
import '../../domain/entities/pharmacy_draft.dart';
import '../../domain/validators.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_info_note.dart';
import '../widgets/auth_message_listener.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/or_divider.dart';

/// For a verified account with no pharmacy yet: every new email
/// registration, and a first-time Google user.
///
/// When the email has a pending invite, it offers to join that pharmacy as
/// a pharmacist or to create a new one. Otherwise it shows only the form
/// to create a pharmacy (the user becomes its owner), pre-filled with what
/// they typed on Register. Needs a [PharmacyChoiceCubit] above it.
class PharmacySetupPage extends StatefulWidget {
  const PharmacySetupPage({super.key});

  @override
  State<PharmacySetupPage> createState() => _PharmacySetupPageState();
}

class _PharmacySetupPageState extends State<PharmacySetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _pharmacyName = TextEditingController();
  final _location = TextEditingController();

  @override
  void dispose() {
    _pharmacyName.dispose();
    _location.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
      AuthPharmacySetupSubmitted(
        pharmacyName: _pharmacyName.text.trim(),
        pharmacyLocation: _location.text.trim(),
      ),
    );
  }

  /// Fills in what was typed on Register, without overwriting anything
  /// the user has typed here since.
  void _prefill(PharmacyDraft? draft) {
    if (draft == null) return;
    if (_pharmacyName.text.isEmpty) _pharmacyName.text = draft.name;
    if (_location.text.isEmpty) _location.text = draft.location;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select(
      (AuthBloc bloc) => bloc.state.user?.email ?? 'your account',
    );
    final saving = context.select(
      (AuthBloc bloc) => bloc.state.isBusy(AuthAction.pharmacySetup),
    );
    final authBusy = context.select((AuthBloc bloc) => bloc.state.isAnyBusy);

    return MultiBlocListener(
      listeners: [
        BlocListener<PharmacyChoiceCubit, PharmacyChoiceState>(
          listenWhen: (previous, current) => previous.draft != current.draft,
          listener: (context, state) => _prefill(state.draft),
        ),
        BlocListener<PharmacyChoiceCubit, PharmacyChoiceState>(
          listenWhen: (previous, current) =>
              current.message != null &&
              previous.messageCount != current.messageCount,
          listener: (context, state) => _showMessage(state.message!),
        ),
      ],
      child: AuthMessageListener(
        actions: const {AuthAction.pharmacySetup, AuthAction.signOut},
        child: BlocBuilder<PharmacyChoiceCubit, PharmacyChoiceState>(
          builder: (context, choice) {
            if (choice.status == PharmacyChoiceStatus.loading) {
              return const AuthScaffold(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 120),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final invite = choice.invite;
            final anyBusy = authBusy || choice.isBusy;

            return AuthScaffold(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    if (invite != null)
                      AuthHeader(
                        title: 'You have been invited',
                        subtitle:
                            'You are signed in as $email. Join the pharmacy '
                            'that invited you, or create your own.',
                        tile: const AuthIconTile(
                          icon: Icons.group_add_outlined,
                          filled: false,
                        ),
                      )
                    else
                      AuthHeader(
                        title: 'Set up your pharmacy',
                        subtitle:
                            'You are signed in as $email. Add your pharmacy '
                            'to start tracking stock and sales. You will be '
                            'its owner.',
                        tile: const AuthIconTile(
                          icon: Icons.storefront_outlined,
                          filled: false,
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (invite != null) ...[
                      _InviteCard(
                        invite: invite,
                        joining: choice.isBusy,
                        onJoin: anyBusy
                            ? null
                            : () => context.read<PharmacyChoiceCubit>().join(),
                      ),
                      const SizedBox(height: 24),
                      const OrDivider(),
                      const SizedBox(height: 16),
                      Text(
                        'Create my own pharmacy',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (choice.inviteCheckFailed) ...[
                      const AuthInfoNote(
                        "We couldn't check for an invite. If your pharmacy "
                        'owner invited you, check again before creating a '
                        'pharmacy.',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: anyBusy
                              ? null
                              : () =>
                                    context.read<PharmacyChoiceCubit>().load(),
                          child: const Text('Check again'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    AuthTextField(
                      label: 'Pharmacy name',
                      controller: _pharmacyName,
                      hint: 'Amani Pharmacy',
                      icon: Icons.local_pharmacy_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => AuthValidators.requiredField(
                        value,
                        'the pharmacy name',
                      ),
                      enabled: !anyBusy,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'Location',
                      controller: _location,
                      hint: 'Gasabo, Kigali',
                      icon: Icons.place_outlined,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (value) =>
                          AuthValidators.requiredField(value, 'the location'),
                      enabled: !anyBusy,
                    ),
                    const SizedBox(height: 24),
                    if (invite != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: anyBusy ? null : _submit,
                          child: saving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Create my pharmacy'),
                        ),
                      )
                    else
                      AuthSubmitButton(
                        label: 'Continue',
                        busy: saving,
                        onPressed: anyBusy ? null : _submit,
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: anyBusy
                            ? null
                            : () => context.read<AuthBloc>().add(
                                const AuthSignOutRequested(),
                              ),
                        child: const Text('Use another account'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The invite: which pharmacy, who sent it, and the Join button.
class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.joining,
    required this.onJoin,
  });

  final PharmacyInvite invite;
  final bool joining;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final inviter = invite.invitedByName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AuthIconTile(icon: Icons.local_pharmacy_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.pharmacyName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inviter == null
                          ? 'Role: Pharmacist'
                          : 'Invited by $inviter · Role: Pharmacist',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AuthSubmitButton(
            label: 'Join ${invite.pharmacyName} as a pharmacist',
            busy: joining,
            onPressed: onJoin,
          ),
        ],
      ),
    );
  }
}
