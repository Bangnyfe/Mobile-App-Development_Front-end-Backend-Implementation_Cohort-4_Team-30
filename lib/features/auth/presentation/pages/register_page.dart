import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/validators.dart';
import '../auth_route_paths.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_message_listener.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_field.dart';

/// Owner registration: creates the account and the pharmacy
/// together. On success AuthBloc's status becomes needsVerification and
/// the router opens Verify email, so there is no navigation code here.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _pharmacyName = TextEditingController();
  final _location = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _password,
      _confirmPassword,
      _pharmacyName,
      _location,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        pharmacyName: _pharmacyName.text.trim(),
        pharmacyLocation: _location.text.trim(),
      ),
    );
  }

  void _backToSignIn() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AuthRoutePaths.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registering = context.select(
      (AuthBloc bloc) => bloc.state.isBusy(AuthAction.register),
    );
    final anyBusy = context.select((AuthBloc bloc) => bloc.state.isAnyBusy);

    return AuthMessageListener(
      actions: const {AuthAction.register},
      child: AuthScaffold(
        showBack: true,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeader(
                  title: 'Create your pharmacy',
                  subtitle: 'Register as the pharmacy owner. You can add '
                      'staff accounts later in Settings.',
                  tile: AuthIconTile(
                    icon: Icons.storefront_outlined,
                    filled: false,
                  ),
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  label: 'Full name',
                  controller: _name,
                  hint: 'Aline Uwase',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: (value) =>
                      AuthValidators.requiredField(value, 'your full name'),
                  enabled: !anyBusy,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'aline@amanipharmacy.rw',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: AuthValidators.email,
                  enabled: !anyBusy,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  textInputAction: TextInputAction.next,
                  isNewPassword: true,
                  validator: AuthValidators.newPassword,
                  enabled: !anyBusy,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmPassword,
                  label: 'Confirm password',
                  textInputAction: TextInputAction.next,
                  isNewPassword: true,
                  validator: (value) =>
                      AuthValidators.confirmPassword(value, _password.text),
                  enabled: !anyBusy,
                ),
                const SizedBox(height: 28),
                const Text(
                  'Pharmacy',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
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
                  hint: 'Nyarugenge, Kigali',
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
                  label: 'Create account',
                  busy: registering,
                  onPressed: anyBusy ? null : _submit,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: anyBusy ? null : _backToSignIn,
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}