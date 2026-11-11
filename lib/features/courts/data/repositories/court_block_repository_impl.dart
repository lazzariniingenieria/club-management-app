import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/court_block.dart';
import '../../domain/entities/court_block_draft.dart';
import '../../domain/repositories/court_block_repository.dart';
import '../datasources/court_block_remote_data_source.dart';

class CourtBlockRepositoryImpl implements CourtBlockRepository {
  final CourtBlockRemoteDataSource remoteDataSource;
  final AppLogger logger;

  CourtBlockRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  static const String _logContext = 'CourtBlockRepository';

  final _blockChanges = StreamController<void>.broadcast();

  @override
  Stream<void> get blockChanges => _blockChanges.stream;

  @override
  Future<Either<Failure, List<CourtBlock>>> loadBlocks(
    int courtId, {
    required DateTime from,
  }) {
    return _guard(
      'loadBlocks',
      () => remoteDataSource.fetchBlocks(courtId, from: from),
    );
  }

  @override
  Future<Either<Failure, void>> createBlock(
    int courtId,
    CourtBlockDraft draft,
  ) {
    return _guardChange(
      'createBlock',
      () => remoteDataSource.createBlock(courtId, draft),
    );
  }

  @override
  Future<Either<Failure, void>> removeBlock(int courtId, int blockId) {
    return _guardChange(
      'removeBlock',
      () => remoteDataSource.removeBlock(courtId, blockId),
    );
  }

  Future<Either<Failure, void>> _guardChange(
    String operation,
    Future<void> Function() run,
  ) async {
    final result = await _guard(operation, run);
    if (_mayHaveChangedBlocks(result)) _blockChanges.add(null);

    return result;
  }

  static bool _mayHaveChangedBlocks(Either<Failure, void> result) {
    return result.fold(
      (failure) =>
          failure is ResponseTimeoutFailure || failure is NotFoundFailure,
      (_) => true,
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
