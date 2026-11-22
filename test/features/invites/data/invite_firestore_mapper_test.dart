import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/invites/data/invite_firestore_mapper.dart';
import 'package:team30_app/features/invites/domain/entities/pharmacy_invite.dart';

void main() {
  group('inviteFromFirestore', () {
    test('reads every field', () {
      final invite = inviteFromFirestore('eric@gmail.com', {
        'pharmacyId': 'p1',
        'pharmacyName': 'Amani Pharmacy',
        'role': 'pharmacist',
        'invitedBy': 'owner-1',
        'invitedByName': 'Aline',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 21, 9)),
      });

      expect(
        invite,
        PharmacyInvite(
          email: 'eric@gmail.com',
          pharmacyId: 'p1',
          pharmacyName: 'Amani Pharmacy',
          invitedBy: 'owner-1',
          invitedByName: 'Aline',
          createdAt: DateTime(2026, 11, 21, 9),
        ),
      );
    });

    test('any status other than pending is not pending', () {
      for (final status in ['accepted', 'revoked', null]) {
        expect(
          inviteFromFirestore('a@b.rw', {'status': status}).isPending,
          isFalse,
          reason: 'status $status',
        );
      }
    });

    test('missing fields get safe defaults', () {
      final invite = inviteFromFirestore('a@b.rw', const {});

      expect(invite.pharmacyName, 'A pharmacy');
      expect(invite.pharmacyId, '');
      expect(invite.invitedByName, isNull);
      expect(invite.createdAt, isNull);
    });
  });

  group('newInviteToFirestore', () {
    test('writes a pending pharmacist invite with a server timestamp', () {
      final data = newInviteToFirestore(
        email: 'eric@gmail.com',
        pharmacyId: 'p1',
        pharmacyName: 'Amani Pharmacy',
        invitedBy: 'owner-1',
        invitedByName: 'Aline',
      );

      expect(data, {
        'email': 'eric@gmail.com',
        'pharmacyId': 'p1',
        'pharmacyName': 'Amani Pharmacy',
        'role': 'pharmacist',
        'invitedBy': 'owner-1',
        'invitedByName': 'Aline',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    test('leaves out a missing inviter name', () {
      final data = newInviteToFirestore(
        email: 'eric@gmail.com',
        pharmacyId: 'p1',
        pharmacyName: 'Amani Pharmacy',
        invitedBy: 'owner-1',
      );

      expect(data.containsKey('invitedByName'), isFalse);
    });
  });
}
