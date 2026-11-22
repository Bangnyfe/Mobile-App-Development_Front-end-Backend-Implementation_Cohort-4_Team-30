import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/pharmacy_draft.dart';
import '../../../auth/domain/repositories/pharmacy_draft_repository.dart';
import '../../domain/entities/pharmacy_invite.dart';
import '../../domain/invite_failure.dart';
import '../../domain/repositories/invite_repository.dart';

part 'pharmacy_choice_state.dart';

/// Drives the "needs pharmacy" step after sign-in: someone verified but not
/// in a pharmacy yet chooses to join the pharmacy that invited them, or to
/// create their own.
///
/// Email and Google sign-ins both reach this step with a verified email,
/// so one invite check here covers both. Creating a pharmacy still goes
/// through AuthBloc; this cubit only handles the invite.
class PharmacyChoiceCubit extends Cubit<PharmacyChoiceState> {
  PharmacyChoiceCubit({
    required InviteRepository inviteRepository,
    required PharmacyDraftRepository draftRepository,
    required this.user,
  }) : _invites = inviteRepository,
       _drafts = draftRepository,
       super(const PharmacyChoiceState());

  final InviteRepository _invites;
  final PharmacyDraftRepository _drafts;

  /// The signed-in user, who has no pharmacy yet.
  final AppUser user;

  /// Looks up the invite and the remembered pharmacy details, together.
  /// Also used by "Check again" after a failed invite check.
  Future<void> load() async {
    emit(state.copyWith(status: PharmacyChoiceStatus.loading));

    final (invite, draft) = await (_findInvite(), _loadDraft()).wait;
    if (isClosed) return;

    emit(
      state.copyWith(
        status: PharmacyChoiceStatus.ready,
        invite: () => invite.invite,
        draft: () => draft,
        inviteCheckFailed: invite.failed,
      ),
    );
  }

  /// Accepts the invite. On success the status stays [joined] until the
  /// router leaves this page.
  Future<void> join() async {
    final invite = state.invite;
    if (invite == null || state.isBusy) return;

    emit(state.copyWith(status: PharmacyChoiceStatus.joining));
    try {
      await _invites.acceptInvite(invite, uid: user.uid, name: user.name);
    } on InviteFailure catch (failure) {
      if (isClosed) return;
      final gone = failure.message == InviteFailure.noLongerAvailable;
      emit(
        state.copyWith(
          status: PharmacyChoiceStatus.ready,
          // A revoked or used invite can't be retried: only Create is left.
          invite: gone ? () => null : null,
          message: failure.message,
        ),
      );
      return;
    }

    try {
      await _drafts.clear(user.uid);
    } on Object catch (_) {
      // A leftover draft is harmless.
    }
    if (!isClosed) emit(state.copyWith(status: PharmacyChoiceStatus.joined));
  }

  Future<({PharmacyInvite? invite, bool failed})> _findInvite() async {
    try {
      return (
        invite: await _invites.findPendingInvite(user.email),
        failed: false,
      );
    } on Object catch (_) {
      return (invite: null, failed: true);
    }
  }

  Future<PharmacyDraft?> _loadDraft() async {
    try {
      return await _drafts.load(user.uid);
    } on Object catch (_) {
      return null;
    }
  }
}
