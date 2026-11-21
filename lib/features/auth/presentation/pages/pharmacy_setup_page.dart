import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/validators.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_message_listener.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';

/// For a signed-in account with no pharmacy yet: a first-time Google user,
/// or a registration whose pharmacy write failed.
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

  @override
  Widget build(BuildContext context) {
    final email = context.select(
      (AuthBloc bloc) => bloc.state.user?.email ?? 'your account',
    );
    final saving = context.select(
      (AuthBloc bloc) => bloc.state.isBusy(AuthAction.pharmacySetup),
    );
    final anyBusy = context.select((AuthBloc bloc) => bloc.state.isAnyBusy);

    return AuthMessageListener(
      actions: const {AuthAction.pharmacySetup, AuthAction.signOut},
      child: AuthScaffold(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              AuthHeader(
                title: 'Set up your pharmacy',
                subtitle:
                    'You are signed in as $email. Add your pharmacy to '
                    'start tracking stock and sales. You will be its owner.',
                tile: const AuthIconTile(
                  icon: Icons.storefront_outlined,
                  filled: false,
                ),
              ),
              const SizedBox(height: 24),
              AuthTextField(
                label: 'Pharmacy name',
                controller: _pharmacyName,
                hint: 'Amani Pharmacy',
                icon: Icons.local_pharmacy_outlined,
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    AuthValidators.requiredField(value, 'the pharmacy name'),
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
      ),
    );
  }
}
