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
import '../widgets/google_sign_in_button.dart';
import '../widgets/or_divider.dart';
import '../widgets/password_field.dart';

/// Sign in with email/password or Google, plus the Google
/// button and Register link.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
      AuthSignInRequested(email: _email.text.trim(), password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signingIn = context.select(
      (AuthBloc bloc) => bloc.state.isBusy(AuthAction.signIn),
    );
    final googleBusy = context.select(
      (AuthBloc bloc) => bloc.state.isBusy(AuthAction.google),
    );
    final anyBusy = context.select((AuthBloc bloc) => bloc.state.isAnyBusy);

    return AuthMessageListener(
      actions: const {AuthAction.signIn, AuthAction.google},
      child: AuthScaffold(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const AuthHeader(
                  title: 'Welcome back',
                  subtitle:
                      'Sign in to manage stock and sales at your '
                      'pharmacy.',
                ),
                const SizedBox(height: 28),
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
                  validator: AuthValidators.loginPassword,
                  onSubmitted: (_) => _submit(),
                  enabled: !anyBusy,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: anyBusy
                        ? null
                        : () => context.push(AuthRoutePaths.forgotPassword),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                AuthSubmitButton(
                  label: 'Sign in',
                  busy: signingIn,
                  onPressed: anyBusy ? null : _submit,
                ),
                const SizedBox(height: 20),
                const OrDivider(),
                const SizedBox(height: 20),
                GoogleSignInButton(
                  busy: googleBusy,
                  onPressed: anyBusy
                      ? null
                      : () => context.read<AuthBloc>().add(
                          const AuthGoogleSignInRequested(),
                        ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('New pharmacy?'),
                      TextButton(
                        onPressed: anyBusy
                            ? null
                            : () => context.push(AuthRoutePaths.register),
                        child: const Text('Create an account'),
                      ),
                    ],
                  ),
                ),
                const Center(
                  child: Text(
                    'Pharmacists join with an invite from their pharmacy owner.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
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
