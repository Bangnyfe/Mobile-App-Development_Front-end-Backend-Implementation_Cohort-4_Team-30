import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pharmacy_account.dart';
import '../../domain/repositories/account_repository.dart';

part 'account_state.dart';

/// Loads the pharmacy, signed-in user, staff and categories once for the
/// Settings tab and its subpages.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._repository) : super(const AccountLoading());

  final AccountRepository _repository;

  static const loadFailedMessage = "Couldn't load your pharmacy details.";

  /// Loads (or reloads, e.g. from a "Try again" button) the account.
  Future<void> load() async {
    emit(const AccountLoading());
    try {
      emit(AccountLoaded(await _repository.load()));
    } catch (_) {
      emit(const AccountFailure(loadFailedMessage));
    }
  }

  Future<void> signOut() => _repository.signOut();
}
