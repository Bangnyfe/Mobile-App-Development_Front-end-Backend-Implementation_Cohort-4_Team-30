import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pharmacy_account.dart';
import '../cubit/account_cubit.dart';

/// Shared layout for the Settings subpages that show account data: an app
/// bar with a back button, then [builder]'s content once loaded, with a
/// spinner while loading and a retry button if loading failed.
class AccountSubpage extends StatelessWidget {
  const AccountSubpage({
    super.key,
    required this.title,
    required this.builder,
    this.actions,
  });

  final String title;
  final List<Widget> Function(BuildContext context, PharmacyAccount account)
  builder;

  /// App bar buttons, shown once the account has loaded.
  final List<Widget> Function(BuildContext context, PharmacyAccount account)?
  actions;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountCubit>().state;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: switch (state) {
          AccountLoaded(:final account) => actions?.call(context, account),
          _ => null,
        },
      ),
      body: SafeArea(
        child: switch (state) {
          AccountLoading() => const Center(child: CircularProgressIndicator()),
          AccountFailure(:final message) => AccountErrorView(message: message),
          AccountLoaded(:final account) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: builder(context, account),
              ),
            ),
          ),
        },
      ),
    );
  }
}

class AccountErrorView extends StatelessWidget {
  const AccountErrorView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.read<AccountCubit>().load(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
