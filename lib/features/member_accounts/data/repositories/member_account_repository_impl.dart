import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/member_account.dart';
import '../../domain/repositories/member_account_repository.dart';
import '../datasources/member_account_remote_data_source.dart';

class MemberAccountRepositoryImpl implements MemberAccountRepository {
  final MemberAccountRemoteDataSource remoteDataSource;
  final AppLogger logger;

  MemberAccountRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  static const String _logContext = 'MemberAccountRepository';

  @override
  Future<Either<Failure, MemberAccount?>> loadAccount(int memberId) =>
      _guard('loadAccount', () => remoteDataSource.fetchAccount(memberId));

  @override
  Future<Either<Failure, MemberAccount>> createAccount(
    int memberId,
    String password,
  ) {
    return _guard(
      'createAccount',
      () => remoteDataSource.createAccount(memberId, password),
    );
  }

  @override
  Future<Either<Failure, MemberAccount>> resetPassword(
    int memberId,
    String newPassword,
  ) {
    return _guard(
      'resetPassword',
      () => remoteDataSource.resetPassword(memberId, newPassword),
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
