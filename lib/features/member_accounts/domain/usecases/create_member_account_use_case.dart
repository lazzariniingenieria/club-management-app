import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../admins/domain/entities/admin_password_rules.dart';
import '../entities/member_account.dart';
import '../repositories/member_account_repository.dart';

class CreateMemberAccountUseCase {
  final MemberAccountRepository repository;

  CreateMemberAccountUseCase(this.repository);

  Future<Either<Failure, MemberAccount>> call(int memberId, String password) {
    if (AdminPasswordRules.check(password) != null) {
      return Future.value(const Left(ValidationFailure('Invalid password')));
    }

    return repository.createAccount(memberId, password);
  }
}
