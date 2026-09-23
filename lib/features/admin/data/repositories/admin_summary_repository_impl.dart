import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/admin_summary.dart';
import '../../domain/repositories/admin_summary_repository.dart';
import '../datasources/admin_summary_remote_data_source.dart';

class AdminSummaryRepositoryImpl implements AdminSummaryRepository {
  final AdminSummaryRemoteDataSource remoteDataSource;
  final AppLogger logger;

  AdminSummaryRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  static const String _logContext = 'AdminSummaryRepository';

  @override
  Future<Either<Failure, AdminSummary>> loadSummary() async {
    try {
      return Right(await remoteDataSource.fetchSummary());
    } catch (error) {
      logger.error('loadSummary failed', context: _logContext, cause: error);

      return Left(failureFromException(error));
    }
  }
}
