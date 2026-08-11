import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<Either<Failure, User>> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(email, password);
      
      await secureStorage.saveToken('access_token', response.token.accessToken);
      await secureStorage.saveToken('refresh_token', response.token.refreshToken);
      
      return Right(response.user);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message ?? 'Invalid credentials'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    // To be implemented when we have the Get User endpoint
    return const Left(ServerFailure('Not implemented yet'));
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await secureStorage.deleteAll();
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to clear local data'));
    }
  }
}
