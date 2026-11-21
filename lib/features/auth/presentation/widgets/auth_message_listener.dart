import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

/// Shows AuthBloc messages for [actions] in a SnackBar: red for failures,
/// default for confirmations ("We sent a reset link").
class AuthMessageListener extends StatelessWidget {
  const AuthMessageListener({
    super.key,
    required this.actions,
    required this.child,
  });

  final Set<AuthAction> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          actions.contains(current.action) &&
          current.message != null &&
          (previous.actionStatus != current.actionStatus ||
              previous.message != current.message),
      listener: (context, state) {
        final isError = state.actionStatus == ActionStatus.failure;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: isError ? AppColors.danger : null,
            ),
          );
      },
      child: child,
    );
  }
}
