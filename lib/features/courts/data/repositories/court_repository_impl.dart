import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_draft.dart';
import '../../domain/repositories/court_repository.dart';
import '../datasources/court_remote_data_source.dart';

class CourtRepositoryImpl implements CourtRepository {
  final CourtRemoteDataSource remoteDataSource;
  final AppLogger logger;

  CourtRepositoryImpl({required this.remoteDataSource, required this.logger});

  static const String _logContext = 'CourtRepository';

  final _courtChanges = StreamController<void>.broadcast();

  @override
  Stream<void> get courtChanges => _courtChanges.stream;

  @override
  Future<Either<Failure, List<Court>>> loadCourts() =>
      _guard('loadCourts', remoteDataSource.fetchCourts);

  @override
  Future<Either<Failure, void>> createCourt(CourtDraft draft) {
    return _guardChange(
      'createCourt',
      () => remoteDataSource.createCourt(draft),
    );
  }

  @override
  Future<Either<Failure, void>> updateCourt(int courtId, CourtDraft draft) {
    return _guardChange(
      'updateCourt',
      () => remoteDataSource.updateCourt(courtId, draft),
    );
  }

  @override
  Future<Either<Failure, void>> setCourtActive(
    int courtId, {
    required bool isActive,
  }) {
    return _guardChange(
      'setCourtActive',
      () => remoteDataSource.setCourtActive(courtId, isActive: isActive),
    );
  }

  Future<Either<Failure, void>> _guardChange(
    String operation,
    Future<void> Function() run,
  ) async {
    final result = await _guard(operation, run);
    if (result.isRight()) _courtChanges.add(null);

    return result;
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
