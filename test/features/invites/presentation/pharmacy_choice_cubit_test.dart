import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/auth/data/in_memory_pharmacy_draft_repository.dart';
import 'package:team30_app/features/auth/domain/entities/app_user.dart';
import 'package:team30_app/features/auth/domain/entities/pharmacy_draft.dart';
import 'package:team30_app/features/invites/data/fake_invite_repository.dart';
import 'package:team30_app/features/invites/domain/entities/pharmacy_invite.dart';
import 'package:team30_app/features/invites/domain/invite_failure.dart';
import 'package:team30_app/features/invites/presentation/cubit/pharmacy_choice_cubit.dart';

const _eric = AppUser(
  uid: 'u2',
  email: 'Eric@Gmail.com',
  name: 'Eric',
  emailVerified: true,
);

const _invite = PharmacyInvite(
  email: 'eric@gmail.com',
  pharmacyId: 'p1',
  pharmacyName: 'Amani Pharmacy',
  invitedBy: 'owner-1',
);

const _draft = PharmacyDraft(
  name: 'Eric Pharmacy',
  district: 'Gasabo',
  city: 'Kigali',
);

void main() {
  late FakeInviteRepository invites;
  late InMemoryPharmacyDraftRepository drafts;

  setUp(() {
    invites = FakeInviteRepository(invites: const [_invite]);
    drafts = InMemoryPharmacyDraftRepository({'u2': _draft});
  });

  PharmacyChoiceCubit buildCubit() {
    final cubit = PharmacyChoiceCubit(
      inviteRepository: invites,
      draftRepository: drafts,
      user: _eric,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('starts loading', () {
    expect(buildCubit().state.status, PharmacyChoiceStatus.loading);
  });

  test('finds the invite for the signed-in email and the draft', () async {
    final cubit = buildCubit();

    await cubit.load();

    expect(cubit.state.status, PharmacyChoiceStatus.ready);
    expect(cubit.state.invite, _invite);
    expect(cubit.state.draft, _draft);
    expect(cubit.state.inviteCheckFailed, isFalse);
  });

  test('without an invite or draft, only Create is left', () async {
    invites = FakeInviteRepository();
    drafts = InMemoryPharmacyDraftRepository();
    final cubit = buildCubit();

    await cubit.load();

    expect(cubit.state.status, PharmacyChoiceStatus.ready);
    expect(cubit.state.invite, isNull);
    expect(cubit.state.draft, isNull);
  });

  test('a failed invite check is reported and can be retried', () async {
    invites.fail = true;
    final cubit = buildCubit();

    await cubit.load();
    expect(cubit.state.inviteCheckFailed, isTrue);
    expect(cubit.state.invite, isNull);
    // The draft still loads.
    expect(cubit.state.draft, _draft);

    invites.fail = false;
    await cubit.load();
    expect(cubit.state.inviteCheckFailed, isFalse);
    expect(cubit.state.invite, _invite);
  });

  test('join accepts the invite and clears the draft', () async {
    final cubit = buildCubit();
    await cubit.load();

    final joining = cubit.join();
    expect(cubit.state.status, PharmacyChoiceStatus.joining);
    expect(cubit.state.isBusy, isTrue);
    await joining;

    expect(cubit.state.status, PharmacyChoiceStatus.joined);
    expect(invites.joined, {'u2': 'p1'});
    expect(await drafts.load('u2'), isNull);
  });

  test('a revoked invite leaves only Create, with a message', () async {
    final cubit = buildCubit();
    await cubit.load();
    await invites.revokeInvite('eric@gmail.com');

    await cubit.join();

    expect(cubit.state.status, PharmacyChoiceStatus.ready);
    expect(cubit.state.invite, isNull);
    expect(cubit.state.message, InviteFailure.noLongerAvailable);
    expect(invites.joined, isEmpty);
    // The draft is kept for Create.
    expect(cubit.state.draft, _draft);
  });

  test('a network error keeps the invite so Join can be retried', () async {
    final cubit = buildCubit();
    await cubit.load();
    invites.fail = true;

    await cubit.join();

    expect(cubit.state.status, PharmacyChoiceStatus.ready);
    expect(cubit.state.invite, _invite);
    expect(cubit.state.message, InviteFailure.generic);
  });

  test('the same message twice is still a new state', () async {
    final cubit = buildCubit();
    await cubit.load();
    invites.fail = true;

    await cubit.join();
    final first = cubit.state;
    await cubit.join();

    expect(cubit.state.message, first.message);
    expect(cubit.state, isNot(first));
  });

  test('join does nothing without an invite', () async {
    invites = FakeInviteRepository();
    final cubit = buildCubit();
    await cubit.load();

    await cubit.join();

    expect(cubit.state.status, PharmacyChoiceStatus.ready);
    expect(invites.joined, isEmpty);
  });
}
