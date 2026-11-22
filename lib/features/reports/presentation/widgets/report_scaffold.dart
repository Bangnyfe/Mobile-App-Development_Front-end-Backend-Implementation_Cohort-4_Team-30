import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/stock_reports_cubit.dart';

/// Shared frame for the stock reports: app bar, loading spinner, error
/// with "Try again", pull to refresh, and a centred, width-capped list for
/// landscape.
class ReportScaffold extends StatelessWidget {
  const ReportScaffold({super.key, required this.title, required this.builder});

  final String title;

  /// Builds the report's rows once the data has loaded.
  final List<Widget> Function(BuildContext context, StockReportsState state)
  builder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: BlocBuilder<StockReportsCubit, StockReportsState>(
          builder: (context, state) => switch (state.status) {
            StockReportsStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            StockReportsStatus.failure => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message ?? StockReportsCubit.loadFailedMessage,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: context.read<StockReportsCubit>().load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
            StockReportsStatus.ready => RefreshIndicator(
              onRefresh: context.read<StockReportsCubit>().load,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: builder(context, state),
                  ),
                ),
              ),
            ),
          },
        ),
      ),
    );
  }
}
