import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member_account.dart';
import '../repositories/member_account_repository.dart';

class LoadMemberAccountUseCase {
  final MemberAccountRepository repository;

  LoadMemberAccountUseCase(this.repository);

  Future<Either<Failure, MemberAccount?>> call(int memberId) =>
      repository.loadAccount(memberId);
}
