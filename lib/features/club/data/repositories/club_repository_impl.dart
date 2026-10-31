import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/club.dart';
import '../../domain/repositories/club_repository.dart';
import '../datasources/club_remote_data_source.dart';

class ClubRepositoryImpl implements ClubRepository {
  final ClubRemoteDataSource remoteDataSource;
  final AppLogger logger;

  ClubRepositoryImpl({required this.remoteDataSource, required this.logger});

  static const String _logContext = 'ClubRepository';

  @override
  Future<Either<Failure, Club>> loadClub() =>
      _guard('loadClub', remoteDataSource.fetchClub);

  @override
  Future<Either<Failure, Club>> updateMonthlyFee(int? monthlyFeeCents) =>
      _guard(
        'updateMonthlyFee',
        () => remoteDataSource.updateMonthlyFee(monthlyFeeCents),
      );

  Future<Either<Failure, Club>> _guard(
    String operation,
    Future<Club> Function() run,
  ) async {
    try {
      return Right(await run());
    } catch (error) {
      logger.error('$operation failed', context: _logContext, cause: error);

      return Left(failureFromException(error));
    }
  }
}
