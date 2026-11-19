import 'package:club_management_app/features/member_accounts/data/models/member_account_model.dart';
import 'package:club_management_app/features/member_accounts/domain/entities/member_account.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/member_account_builders.dart';

void main() {
  test('reads the account the member signs in with', () {
    final account = MemberAccountModel.fromJson(memberAccountJson());

    expect(account.id, 40);
    expect(account.memberId, 34);
    expect(account.dni, '30111222');
    expect(account.role, MemberAccountRole.member);
    expect(account.isActive, isTrue);
    expect(account.canResetPassword, isTrue);
  });

  test('an admin account cannot have its password reset from here', () {
    final account =
        MemberAccountModel.fromJson(memberAccountJson(role: 'ADMIN'));

    expect(account.role, MemberAccountRole.admin);
    expect(account.canResetPassword, isFalse);
  });

  test('sends the initial password under password', () {
    expect(
      MemberAccountModel.bodyForCreate('s3cr3t123'),
      {'password': 's3cr3t123'},
    );
  });

  test('sends a reset password under newPassword', () {
    expect(
      MemberAccountModel.bodyForReset('n3wS3cr3t'),
      {'newPassword': 'n3wS3cr3t'},
    );
  });
}
