import 'package:flutter/material.dart';

import 'auth_text_field.dart';

/// Password field with a show/hide button.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.isNewPassword = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// Lets the phone's password manager suggest a strong new password.
  final bool isNewPassword;
  final bool enabled;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  final _obscured = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _obscured.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _obscured,
      builder: (context, obscured, _) => AuthTextField(
        label: widget.label,
        controller: widget.controller,
        hint: '••••••••',
        icon: Icons.lock_outline,
        validator: widget.validator,
        obscureText: obscured,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        enabled: widget.enabled,
        autofillHints: [
          widget.isNewPassword
              ? AutofillHints.newPassword
              : AutofillHints.password,
        ],
        suffix: IconButton(
          tooltip: obscured ? 'Show password' : 'Hide password',
          icon: Icon(
            obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
          ),
          onPressed: () => _obscured.value = !obscured,
        ),
      ),
    );
  }
}
