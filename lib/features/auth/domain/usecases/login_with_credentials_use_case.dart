import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithCredentialsUseCase {
  final AuthRepository repository;

  LoginWithCredentialsUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String dni,
    required String password,
  }) async {
    if (dni.trim().isEmpty || password.trim().isEmpty) {
      return const Left(ValidationFailure('DNI and password cannot be empty'));
    }

    return await repository.loginWithCredentials(
      dni: dni.trim(),
      password: password,
    );
  }
}
