part of 'account_cubit.dart';

sealed class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

final class AccountLoading extends AccountState {
  const AccountLoading();
}

final class AccountLoaded extends AccountState {
  const AccountLoaded(this.account);

  final PharmacyAccount account;

  @override
  List<Object?> get props => [account];
}

final class AccountFailure extends AccountState {
  const AccountFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
