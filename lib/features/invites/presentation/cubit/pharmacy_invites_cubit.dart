import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pharmacy_invite.dart';
import '../../domain/invite_failure.dart';
import '../../domain/repositories/invite_repository.dart';

part 'pharmacy_invites_state.dart';

/// The owner's pending invites on Settings > Staff, plus sending and
/// revoking them. Only created for a signed-in owner.
class PharmacyInvitesCubit extends Cubit<PharmacyInvitesState> {
  PharmacyInvitesCubit({
    required InviteRepository inviteRepository,
    required this.pharmacyId,
    required this.ownerUid,
    this.ownerName,
  }) : _repository = inviteRepository,
       super(const PharmacyInvitesLoading());

  final InviteRepository _repository;
  final String pharmacyId;
  final String ownerUid;
  final String? ownerName;

  StreamSubscription<List<PharmacyInvite>>? _subscription;

  static const loadFailedMessage = "Couldn't load pending invites.";

  /// Starts (or restarts, from "Try again") watching the pending invites.
  void start() {
    unawaited(_subscription?.cancel());
    emit(const PharmacyInvitesLoading());
    _subscription = _repository
        .watchPendingInvites(pharmacyId)
        .listen(
          (invites) => emit(PharmacyInvitesLoaded(invites)),
          onError: (Object _) =>
              emit(const PharmacyInvitesFailure(loadFailedMessage)),
        );
  }

  /// Invites [email]. Returns null when sent, or the message to show.
  /// The list updates by itself through the stream.
  Future<String?> send(String email) => _run(
    () => _repository.sendInvite(
      email: email,
      pharmacyId: pharmacyId,
      invitedBy: ownerUid,
      invitedByName: ownerName,
    ),
  );

  /// Cancels the invite for [email]. Returns null when done, or the
  /// message to show.
  Future<String?> revoke(String email) =>
      _run(() => _repository.revokeInvite(email));

  Future<String?> _run(Future<Object?> Function() action) async {
    try {
      await action();
      return null;
    } on InviteFailure catch (failure) {
      return failure.message;
    } on Object catch (_) {
      return InviteFailure.generic;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
