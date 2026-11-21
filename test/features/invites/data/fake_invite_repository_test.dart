import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/invites/data/fake_invite_repository.dart';
import 'package:team30_app/features/invites/domain/entities/pharmacy_invite.dart';
import 'package:team30_app/features/invites/domain/invite_failure.dart';

FakeInviteRepository buildRepository({
  List<PharmacyInvite> invites = const [],
}) => FakeInviteRepository(
  invites: invites,
  pharmacyNames: const {'p1': 'Amani Pharmacy', 'p2': 'Kacyiru Pharmacy'},
  clock: () => DateTime(2026, 11, 21, 9),
);

Future<void> expectFailure(Future<void> call, String message) => expectLater(
  call,
  throwsA(isA<InviteFailure>().having((f) => f.message, 'message', message)),
);

void main() {
  test('normalizeEmail ignores case and surrounding spaces', () {
    expect(PharmacyInvite.normalizeEmail(' Eric@Gmail.COM '), 'eric@gmail.com');
  });

  group('sendInvite', () {
    test('creates a pending invite with the pharmacy name', () async {
      final repository = buildRepository();

      final invite = await repository.sendInvite(
        email: ' Eric@Gmail.com',
        pharmacyId: 'p1',
        invitedBy: 'owner-1',
        invitedByName: 'Aline',
      );

      expect(invite.email, 'eric@gmail.com');
      expect(invite.pharmacyName, 'Amani Pharmacy');
      expect(invite.isPending, isTrue);
      expect(await repository.findPendingInvite('ERIC@gmail.com'), invite);
    });

    test('refuses a second invite for the same email', () async {
      final repository = buildRepository();
      await repository.sendInvite(
        email: 'eric@gmail.com',
        pharmacyId: 'p1',
        invitedBy: 'owner-1',
      );

      await expectFailure(
        repository.sendInvite(
          email: 'eric@gmail.com',
          pharmacyId: 'p1',
          invitedBy: 'owner-1',
        ),
        InviteFailure.alreadyInvited,
      );
      await expectFailure(
        repository.sendInvite(
          email: 'eric@gmail.com',
          pharmacyId: 'p2',
          invitedBy: 'owner-2',
        ),
        InviteFailure.invitedElsewhere,
      );
    });

    test('can invite again after the invite was accepted', () async {
      final repository = buildRepository();
      final first = await repository.sendInvite(
        email: 'eric@gmail.com',
        pharmacyId: 'p1',
        invitedBy: 'owner-1',
      );
      await repository.acceptInvite(first, uid: 'u2', name: 'Eric');

      final second = await repository.sendInvite(
        email: 'eric@gmail.com',
        pharmacyId: 'p2',
        invitedBy: 'owner-2',
      );

      expect(second.pharmacyId, 'p2');
    });
  });

  group('acceptInvite', () {
    test('joins the pharmacy and the invite stops being pending', () async {
      final repository = buildRepository();
      final invite = await repository.sendInvite(
        email: 'eric@gmail.com',
        pharmacyId: 'p1',
        invitedBy: 'owner-1',
      );

      await repository.acceptInvite(invite, uid: 'u2', name: 'Eric');

      expect(repository.joined, {'u2': 'p1'});
      expect(await repository.findPendingInvite('eric@gmail.com'), isNull);
    });

    test('fails when the invite was revoked meanwhile', () async {
      final repository = buildRepository();
      final invite = await repository.sendInvite(
        email: 'eric@gmail.com',
        pharmacyId: 'p1',
        invitedBy: 'owner-1',
      );
      await repository.revokeInvite('eric@gmail.com');

      await expectFailure(
        repository.acceptInvite(invite, uid: 'u2', name: 'Eric'),
        InviteFailure.noLongerAvailable,
      );
      expect(repository.joined, isEmpty);
    });
  });

  test('watchPendingInvites lists only this pharmacy, live', () async {
    final repository = buildRepository();
    final updates = <List<String>>[];
    final subscription = repository
        .watchPendingInvites('p1')
        .listen((invites) => updates.add([for (final i in invites) i.email]));
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await repository.sendInvite(
      email: 'eric@gmail.com',
      pharmacyId: 'p1',
      invitedBy: 'owner-1',
    );
    await repository.sendInvite(
      email: 'grace@gmail.com',
      pharmacyId: 'p2',
      invitedBy: 'owner-2',
    );
    await repository.revokeInvite('eric@gmail.com');
    await pumpEventQueue();

    expect(updates, [
      <String>[],
      ['eric@gmail.com'],
      ['eric@gmail.com'],
      <String>[],
    ]);
  });

  test('fail makes every call throw', () async {
    final repository = buildRepository()..fail = true;

    await expectFailure(
      repository.findPendingInvite('eric@gmail.com'),
      InviteFailure.generic,
    );
  });
}
