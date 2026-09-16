import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RestoreSessionUseCase {
  final AuthRepository repository;

  RestoreSessionUseCase(this.repository);

  Future<Either<Failure, User?>> call() => repository.restoreSession();
}
