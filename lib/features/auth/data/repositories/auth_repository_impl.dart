import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final AppLogger logger;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.logger,
  });

  static const String _logContext = 'AuthRepository';

  @override
  Future<Either<Failure, User>> loginWithCredentials({
    required String dni,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(dni, password);
      await localDataSource.saveSession(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        user: response.user,
      );
      return Right(response.user);
    } catch (error) {
      return Left(_mapToFailure(error, 'loginWithCredentials'));
    }
  }

  @override
  Future<Either<Failure, User?>> restoreSession() async {
    try {
      if (!await localDataSource.hasSession()) return const Right(null);
      return Right(await localDataSource.readUser());
    } catch (error) {
      logger.error(
        'Could not restore session, clearing it',
        context: _logContext,
        cause: error,
      );
      await localDataSource.clearSession();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearSession();
      return const Right(null);
    } catch (error) {
      return Left(_mapToFailure(error, 'logout'));
    }
  }

  Failure _mapToFailure(Object error, String operation) {
    logger.error('$operation failed', context: _logContext, cause: error);

    return failureFromException(error);
  }
}
