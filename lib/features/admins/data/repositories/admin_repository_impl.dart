import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;
  final AppLogger logger;

  AdminRepositoryImpl({required this.remoteDataSource, required this.logger});

  static const String _logContext = 'AdminRepository';

  @override
  Future<Either<Failure, void>> resetPassword(int adminId, String newPassword) {
    return _guard(
      'resetPassword',
      () => remoteDataSource.resetPassword(adminId, newPassword),
    );
  }

  Future<Either<Failure, T>> _guard<T>(
    String operation,
    Future<T> Function() run,
  ) async {
    try {
      return Right(await run());
    } catch (error) {
      logger.error('$operation failed', context: _logContext, cause: error);

      return Left(failureFromException(error));
    }
  }
}
