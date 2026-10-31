import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class SetAdminActiveUseCase {
  final AdminRepository repository;

  SetAdminActiveUseCase(this.repository);

  Future<Either<Failure, void>> call(int adminId, {required bool isActive}) =>
      repository.setAdminActive(adminId, isActive: isActive);
}
