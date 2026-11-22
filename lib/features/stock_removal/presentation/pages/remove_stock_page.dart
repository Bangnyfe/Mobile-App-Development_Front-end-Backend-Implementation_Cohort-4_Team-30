import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/remove_stock_cubit.dart';
import '../widgets/choose_batch_view.dart';
import '../widgets/reason_view.dart';
import '../widgets/removal_done_view.dart';

/// The Remove stock flow: Choose batch, Reason, then the
/// confirmation, as one full-screen page driven by [RemoveStockCubit].
///
/// System back on the Reason step returns to Choose batch instead of
/// leaving, so the selection is never lost by accident.
class RemoveStockPage extends StatelessWidget {
  const RemoveStockPage({super.key, this.clock = DateTime.now});

  /// For tests; the app uses the real time.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final alertDays = context.select(
      (SettingsCubit cubit) => cubit.state.settings.expiryAlertDays,
    );

    return BlocConsumer<RemoveStockCubit, RemoveStockState>(
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus &&
          current.submitStatus == SubmitStatus.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.message ?? "Couldn't remove the stock."),
              backgroundColor: AppColors.danger,
            ),
          );
      },
      builder: (context, state) {
        final cubit = context.read<RemoveStockCubit>();
        final onReasonStep =
            state.status == RemoveStockStatus.ready &&
            state.step == RemoveStockStep.reason;
        final done = state.step == RemoveStockStep.done;

        return PopScope(
          canPop: !onReasonStep,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.backToBatch();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Remove stock'),
              automaticallyImplyLeading: false,
              leading: done
                  ? null
                  : onReasonStep
                  ? BackButton(onPressed: cubit.backToBatch)
                  : CloseButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
            ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey('${state.status}-${state.step}'),
                child: _body(state, cubit, alertDays),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(RemoveStockState state, RemoveStockCubit cubit, int alertDays) {
    switch (state.status) {
      case RemoveStockStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case RemoveStockStatus.loadFailure:
        return _LoadError(
          message: state.message ?? RemoveStockCubit.loadFailedMessage,
          onRetry: cubit.start,
        );
      case RemoveStockStatus.ready:
        final today = clock();
        return switch (state.step) {
          RemoveStockStep.chooseBatch => ChooseBatchView(
            state: state,
            today: today,
            alertDays: alertDays,
          ),
          RemoveStockStep.reason => ReasonView(state: state, today: today),
          RemoveStockStep.done => RemovalDoneView(state: state),
        };
    }
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
