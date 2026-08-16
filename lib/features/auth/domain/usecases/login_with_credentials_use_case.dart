import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithCredentialsUseCase {
  final AuthRepository repository;

  LoginWithCredentialsUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return const Left(AuthFailure('Email and password cannot be empty'));
    }
    
    return await repository.loginWithCredentials(
      email: email,
      password: password,
    );
  }
}
