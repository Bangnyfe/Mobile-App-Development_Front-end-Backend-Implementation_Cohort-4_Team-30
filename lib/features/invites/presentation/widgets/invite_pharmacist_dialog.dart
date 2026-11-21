import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/validators.dart';

/// Asks for the email to invite. [onSend] returns null when the invite was
/// sent (the dialog then closes and returns the email), or a message to
/// show under the field so the owner can fix it.
class InvitePharmacistDialog extends StatefulWidget {
  const InvitePharmacistDialog({super.key, required this.onSend});

  final Future<String?> Function(String email) onSend;

  /// Shows the dialog. Resolves to the invited email, or null if cancelled.
  static Future<String?> show(
    BuildContext context, {
    required Future<String?> Function(String email) onSend,
  }) => showDialog<String>(
    context: context,
    builder: (_) => InvitePharmacistDialog(onSend: onSend),
  );

  @override
  State<InvitePharmacistDialog> createState() => _InvitePharmacistDialogState();
}

class _InvitePharmacistDialogState extends State<InvitePharmacistDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    setState(() {
      _sending = true;
      _error = null;
    });

    final error = await widget.onSend(email);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(email);
    } else {
      setState(() {
        _sending = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite a pharmacist'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'They sign up or sign in with this email and choose to join '
              'your pharmacy. Let them know yourself, for example on '
              'WhatsApp: no email is sent.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              autofocus: true,
              enabled: !_sending,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'eric@gmail.com',
                errorText: _error,
                errorMaxLines: 3,
              ),
              validator: AuthValidators.email,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onFieldSubmitted: (_) => _send(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Send invite'),
        ),
      ],
    );
  }
}
