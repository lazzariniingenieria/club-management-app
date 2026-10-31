import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin_password_rules.dart';
import '../repositories/admin_repository.dart';

class ChangeOwnPasswordUseCase {
  final AdminRepository repository;

  ChangeOwnPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String newPassword) {
    if (AdminPasswordRules.check(newPassword) != null) {
      return Future.value(const Left(ValidationFailure('Invalid password')));
    }

    return repository.changeOwnPassword(newPassword);
  }
}
