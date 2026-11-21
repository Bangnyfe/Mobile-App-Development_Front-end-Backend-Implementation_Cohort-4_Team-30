import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/validators.dart';
import '../auth_route_paths.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_info_note.dart';
import '../widgets/auth_message_listener.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
      AuthPasswordResetRequested(_email.text.trim()),
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
    final sending = context.select(
      (AuthBloc bloc) => bloc.state.isBusy(AuthAction.passwordReset),
    );

    return AuthMessageListener(
      actions: const {AuthAction.passwordReset},
      child: AuthScaffold(
        showBack: true,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthHeader(
                title: 'Reset your password',
                subtitle:
                    'Enter the email on your account. We will send you '
                    'a link to choose a new password.',
                tile: AuthIconTile(icon: Icons.lock_outline, filled: false),
              ),
              const SizedBox(height: 24),
              AuthTextField(
                label: 'Email',
                controller: _email,
                hint: 'aline@amanipharmacy.rw',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: AuthValidators.email,
                enabled: !sending,
              ),
              const SizedBox(height: 20),
              AuthSubmitButton(
                label: 'Send reset link',
                busy: sending,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              const AuthInfoNote(
                'Pharmacists: if the email does not arrive, ask your '
                'pharmacy owner for help.',
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: sending ? null : _backToSignIn,
                  child: const Text('Back to sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
