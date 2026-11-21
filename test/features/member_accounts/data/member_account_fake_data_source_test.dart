import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/admins/data/datasources/admin_fake_data_source.dart';
import 'package:club_management_app/features/admins/data/datasources/fake_user_account_store.dart';
import 'package:club_management_app/features/club/data/datasources/club_fake_data_source.dart';
import 'package:club_management_app/features/member_accounts/data/datasources/member_account_fake_data_source.dart';
import 'package:club_management_app/features/member_accounts/domain/entities/member_account.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:club_management_app/features/members/domain/entities/member_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const memberWithAccount = 2;
  const memberLinkedToAdmin = 1;
  const memberWithoutAccount = 4;
  const inactiveMember = 36;

  late MemberFakeDataSource members;

  MemberAccountFakeDataSource buildSource({bool memberAppEnabled = true}) {
    members = MemberFakeDataSource(latency: Duration.zero);

    return MemberAccountFakeDataSource(
      members: members,
      accounts: FakeUserAccountStore(),
      club: ClubFakeDataSource(
        latency: Duration.zero,
        memberAppEnabled: memberAppEnabled,
      ),
      latency: Duration.zero,
    );
  }

  group('fetchAccount', () {
    test('a seeded member signs in with a member account', () async {
      final account = await buildSource().fetchAccount(memberWithAccount);

      expect(account?.role, MemberAccountRole.member);
      expect(account?.dni, '20013577');
    });

    test('the member linked to an admin has an admin account', () async {
      final account = await buildSource().fetchAccount(memberLinkedToAdmin);

      expect(account?.role, MemberAccountRole.admin);
    });

    test('an admin linked to a member keeps the account as a member', () async {
      final store = FakeUserAccountStore();
      final admins = AdminFakeDataSource(latency: Duration.zero, accounts: store);
      final source = MemberAccountFakeDataSource(
        members: MemberFakeDataSource(latency: Duration.zero),
        club: ClubFakeDataSource(latency: Duration.zero),
        accounts: store,
        latency: Duration.zero,
      );

      await admins.setAdminActive(3, isActive: false);
      final account = await source.fetchAccount(memberLinkedToAdmin);

      expect(account?.role, MemberAccountRole.member);
      expect(account?.id, 3);
    });

    test('most members have no account', () async {
      expect(await buildSource().fetchAccount(memberWithoutAccount), isNull);
    });

    test('a member outside the club is not found', () async {
      await expectLater(
        buildSource().fetchAccount(999),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('createAccount', () {
    test('creates a member account with the dni of the member', () async {
      final source = buildSource();

      final account =
          await source.createAccount(memberWithoutAccount, 's3cr3t123');

      expect(account.role, MemberAccountRole.member);
      expect(account.dni, '20040731');
      expect(await source.fetchAccount(memberWithoutAccount), account);
    });

    test('is rejected while the club has the member app off', () async {
      await expectLater(
        buildSource(memberAppEnabled: false)
            .createAccount(memberWithoutAccount, 's3cr3t123'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('is rejected for a deactivated member', () async {
      await expectLater(
        buildSource().createAccount(inactiveMember, 's3cr3t123'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('is rejected for a member without a dni', () async {
      final source = buildSource();
      await members.updateMember(
        memberWithoutAccount,
        const MemberDraft(firstName: 'Lucía', lastName: 'Álvarez', dni: ''),
      );

      await expectLater(
        source.createAccount(memberWithoutAccount, 's3cr3t123'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('conflicts when the member already has an account', () async {
      final source = buildSource();

      await expectLater(
        source.createAccount(memberWithAccount, 's3cr3t123'),
        throwsA(isA<ConflictException>()),
      );
      await expectLater(
        source.createAccount(memberLinkedToAdmin, 's3cr3t123'),
        throwsA(isA<ConflictException>()),
      );
    });

    test('conflicts when another account uses the dni of the member', () async {
      final source = buildSource();
      await members.updateMember(
        memberWithoutAccount,
        const MemberDraft(
          firstName: 'Lucía',
          lastName: 'Álvarez',
          dni: '11111111',
        ),
      );

      await expectLater(
        source.createAccount(memberWithoutAccount, 's3cr3t123'),
        throwsA(isA<ConflictException>()),
      );
    });

    test('a member outside the club is not found', () async {
      await expectLater(
        buildSource().createAccount(999, 's3cr3t123'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('resetPassword', () {
    test('returns the member account', () async {
      final account =
          await buildSource().resetPassword(memberWithAccount, 'n3wS3cr3t');

      expect(account.memberId, memberWithAccount);
    });

    test('an admin account is not a member account', () async {
      await expectLater(
        buildSource().resetPassword(memberLinkedToAdmin, 'n3wS3cr3t'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('a member without an account is not found', () async {
      await expectLater(
        buildSource().resetPassword(memberWithoutAccount, 'n3wS3cr3t'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
