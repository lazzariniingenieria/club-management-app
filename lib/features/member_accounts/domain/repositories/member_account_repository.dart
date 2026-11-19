import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member_account.dart';

abstract class MemberAccountRepository {
  Future<Either<Failure, MemberAccount?>> loadAccount(int memberId);

  Future<Either<Failure, MemberAccount>> createAccount(
    int memberId,
    String password,
  );

  Future<Either<Failure, MemberAccount>> resetPassword(
    int memberId,
    String newPassword,
  );
}
