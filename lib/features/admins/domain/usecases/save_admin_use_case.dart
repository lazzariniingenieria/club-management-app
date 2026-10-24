import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin_draft.dart';
import '../entities/admin_password_rules.dart';
import '../repositories/admin_repository.dart';

class SaveAdminUseCase {
  final AdminRepository repository;

  SaveAdminUseCase(this.repository);

  Future<Either<Failure, void>> create(AdminDraft draft, String password) {
    if (AdminPasswordRules.check(password) != null) {
      return Future.value(const Left(ValidationFailure('Invalid password')));
    }

    return repository.createAdmin(draft.trimmed(), password);
  }

  Future<Either<Failure, void>> update(int adminId, AdminDraft draft) =>
      repository.updateAdmin(adminId, draft.trimmed());
}
