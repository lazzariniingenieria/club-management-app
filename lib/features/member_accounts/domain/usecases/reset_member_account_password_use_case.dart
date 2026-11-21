import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../admins/domain/entities/admin_password_rules.dart';
import '../entities/member_account.dart';
import '../repositories/member_account_repository.dart';

class ResetMemberAccountPasswordUseCase {
  final MemberAccountRepository repository;

  ResetMemberAccountPasswordUseCase(this.repository);

  Future<Either<Failure, MemberAccount>> call(
    int memberId,
    String newPassword,
  ) {
    if (AdminPasswordRules.check(newPassword) != null) {
      return Future.value(const Left(ValidationFailure('Invalid password')));
    }

    return repository.resetPassword(memberId, newPassword);
  }
}
