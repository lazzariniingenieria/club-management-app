import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() => repository.logout();
}
