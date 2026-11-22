import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/invites/data/fake_invite_repository.dart';
import 'package:team30_app/features/invites/domain/entities/pharmacy_invite.dart';
import 'package:team30_app/features/invites/domain/invite_failure.dart';
import 'package:team30_app/features/invites/presentation/cubit/pharmacy_invites_cubit.dart';

void main() {
  late FakeInviteRepository repository;

  setUp(() {
    repository = FakeInviteRepository(
      pharmacyNames: const {'p1': 'Amani Pharmacy'},
      clock: () => DateTime(2026, 11, 21, 9),
    );
  });

  PharmacyInvitesCubit buildCubit() {
    final cubit = PharmacyInvitesCubit(
      inviteRepository: repository,
      pharmacyId: 'p1',
      ownerUid: 'owner-1',
      ownerName: 'Aline',
    );
    addTearDown(cubit.close);
    return cubit;
  }

  List<String> emails(PharmacyInvitesCubit cubit) => [
    for (final invite in (cubit.state as PharmacyInvitesLoaded).invites)
      invite.email,
  ];

  test('starts loading, then lists the pending invites', () async {
    final cubit = buildCubit();
    expect(cubit.state, const PharmacyInvitesLoading());

    cubit.start();
    await pumpEventQueue();

    expect(cubit.state, const PharmacyInvitesLoaded([]));
  });

  test('a sent invite appears in the list, from this owner', () async {
    final cubit = buildCubit()..start();

    final error = await cubit.send(' Eric@Gmail.com ');
    await pumpEventQueue();

    expect(error, isNull);
    expect(emails(cubit), ['eric@gmail.com']);
    final invite = (cubit.state as PharmacyInvitesLoaded).invites.single;
    expect(invite.invitedBy, 'owner-1');
    expect(invite.invitedByName, 'Aline');
    expect(invite.pharmacyName, 'Amani Pharmacy');
  });

  test('sending the same email twice returns the message', () async {
    final cubit = buildCubit()..start();
    await cubit.send('eric@gmail.com');

    expect(await cubit.send('eric@gmail.com'), InviteFailure.alreadyInvited);
  });

  test('revoking removes the invite from the list', () async {
    final cubit = buildCubit()..start();
    await cubit.send('eric@gmail.com');

    expect(await cubit.revoke('eric@gmail.com'), isNull);
    await pumpEventQueue();

    expect(emails(cubit), isEmpty);
    expect(await repository.findPendingInvite('eric@gmail.com'), isNull);
  });

  test('a failure returns the generic message', () async {
    final cubit = buildCubit()..start();
    repository.fail = true;

    expect(await cubit.send('eric@gmail.com'), InviteFailure.generic);
    expect(await cubit.revoke('eric@gmail.com'), InviteFailure.generic);
  });

  test('a list that fails to load can be retried', () async {
    repository.fail = true;
    final cubit = buildCubit()..start();
    await pumpEventQueue();
    expect(
      cubit.state,
      const PharmacyInvitesFailure(PharmacyInvitesCubit.loadFailedMessage),
    );

    repository.fail = false;
    cubit.start();
    await pumpEventQueue();
    expect(cubit.state, const PharmacyInvitesLoaded(<PharmacyInvite>[]));
  });
}
