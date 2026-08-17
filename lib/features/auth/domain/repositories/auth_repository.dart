import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> loginWithCredentials({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> getCurrentUser();
  
  Future<Either<Failure, void>> logout();
}
