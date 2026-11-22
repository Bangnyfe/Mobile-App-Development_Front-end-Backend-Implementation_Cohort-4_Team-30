part of 'pharmacy_invites_cubit.dart';

sealed class PharmacyInvitesState extends Equatable {
  const PharmacyInvitesState();

  @override
  List<Object?> get props => [];
}

final class PharmacyInvitesLoading extends PharmacyInvitesState {
  const PharmacyInvitesLoading();
}

final class PharmacyInvitesLoaded extends PharmacyInvitesState {
  const PharmacyInvitesLoaded(this.invites);

  /// Oldest first. Empty when nobody is waiting to join.
  final List<PharmacyInvite> invites;

  @override
  List<Object?> get props => [invites];
}

final class PharmacyInvitesFailure extends PharmacyInvitesState {
  const PharmacyInvitesFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
