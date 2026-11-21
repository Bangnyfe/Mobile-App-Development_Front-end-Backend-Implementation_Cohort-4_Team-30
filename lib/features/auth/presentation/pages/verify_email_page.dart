import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_info_note.dart';
import '../widgets/auth_message_listener.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_submit_button.dart';

/// Shown after registration, and whenever an unverified account signs in
/// The app stays here until the email link has been opened.
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = context.select(
      (AuthBloc bloc) => bloc.state.user?.email ?? 'your email',
    );
    final checking = context.select(
      (AuthBloc bloc) => bloc.state.isBusy(AuthAction.checkVerification),
    );
    final resending = context.select(
      (AuthBloc bloc) => bloc.state.isBusy(AuthAction.resendVerification),
    );
    final anyBusy = context.select((AuthBloc bloc) => bloc.state.isAnyBusy);
    final auth = context.read<AuthBloc>();

    return AuthMessageListener(
      actions: const {
        AuthAction.checkVerification,
        AuthAction.resendVerification,
        AuthAction.signOut,
      },
      child: AuthScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            AuthHeader(
              title: 'Verify your email',
              subtitle:
                  'We sent a verification link to $email. Open it, '
                  'then come back and tap the button below.',
              tile: const AuthIconTile(
                icon: Icons.mark_email_unread_outlined,
                filled: false,
              ),
            ),
            const SizedBox(height: 24),
            AuthSubmitButton(
              label: "I've verified my email",
              busy: checking,
              onPressed: anyBusy
                  ? null
                  : () => auth.add(const AuthVerificationChecked()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: anyBusy
                    ? null
                    : () => auth.add(const AuthVerificationEmailResent()),
                child: resending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Resend email'),
              ),
            ),
            const SizedBox(height: 16),
            const AuthInfoNote(
              "Can't find it? Check your spam or promotions folder.",
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: anyBusy
                    ? null
                    : () => auth.add(const AuthSignOutRequested()),
                child: const Text('Use another account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
