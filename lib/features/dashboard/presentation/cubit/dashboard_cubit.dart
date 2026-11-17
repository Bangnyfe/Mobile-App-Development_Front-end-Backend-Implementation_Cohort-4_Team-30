import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';

part 'dashboard_state.dart';

/// Listens to the dashboard summary stream and exposes it as UI state.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardLoading());

  final DashboardRepository _repository;
  StreamSubscription<DashboardSummary>? _subscription;

  /// Starts (or restarts, e.g. from a "Try again" button) listening.
  void start() {
    _subscription?.cancel();
    emit(const DashboardLoading());
    _subscription = _repository.watchSummary().listen(
      (summary) => emit(DashboardLoaded(summary)),
      onError: (Object _) => emit(
        const DashboardFailure('Could not load the dashboard. Try again.'),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
