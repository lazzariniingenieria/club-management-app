import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin_password_rules.dart';
import '../repositories/admin_repository.dart';

class ResetAdminPasswordUseCase {
  final AdminRepository repository;

  ResetAdminPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(int adminId, String newPassword) {
    if (AdminPasswordRules.check(newPassword) != null) {
      return Future.value(const Left(ValidationFailure('Invalid password')));
    }

    return repository.resetPassword(adminId, newPassword);
  }
}
