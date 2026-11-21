import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/admins/domain/repositories/admin_repository.dart';
import 'package:club_management_app/features/member_accounts/domain/entities/member_account.dart';
import 'package:club_management_app/features/member_accounts/domain/repositories/member_account_repository.dart';
import 'package:club_management_app/features/member_accounts/domain/usecases/promote_member_to_admin_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

class MockMemberAccountRepository extends Mock
    implements MemberAccountRepository {}

const int memberId = 34;

MemberAccount accountWith(MemberAccountRole role) => MemberAccount(
      id: 40,
      memberId: memberId,
      dni: '30111222',
      role: role,
      isActive: true,
    );

void main() {
  late MockAdminRepository admins;
  late MockMemberAccountRepository accounts;
  late PromoteMemberToAdminUseCase promote;

  void promotionFails(Failure failure) {
    when(() => admins.promoteMember(memberId))
        .thenAnswer((_) async => Left(failure));
  }

  void accountIs(MemberAccountRole role) {
    when(() => accounts.loadAccount(memberId))
        .thenAnswer((_) async => Right(accountWith(role)));
  }

  setUp(() {
    admins = MockAdminRepository();
    accounts = MockMemberAccountRepository();
    promote = PromoteMemberToAdminUseCase(admins: admins, accounts: accounts);
  });

  test('a promotion that answers is not rechecked', () async {
    when(() => admins.promoteMember(memberId))
        .thenAnswer((_) async => const Right(null));

    expect((await promote(memberId)).isRight(), isTrue);
    verifyNever(() => accounts.loadAccount(any()));
  });

  test('a timed out promotion that went through counts as done', () async {
    promotionFails(const ResponseTimeoutFailure());
    accountIs(MemberAccountRole.admin);

    expect((await promote(memberId)).isRight(), isTrue);
  });

  test('a timed out promotion that did not go through fails', () async {
    promotionFails(const ResponseTimeoutFailure());
    accountIs(MemberAccountRole.member);

    final result = await promote(memberId);

    expect(result.getLeft().toNullable(), isA<ResponseTimeoutFailure>());
  });

  test('a member without a member account is reported as is', () async {
    promotionFails(const NotFoundFailure());

    final result = await promote(memberId);

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    verifyNever(() => accounts.loadAccount(any()));
  });
}
