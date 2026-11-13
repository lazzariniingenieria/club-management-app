import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/court_block.dart';
import '../repositories/court_block_repository.dart';

class LoadCourtBlocksUseCase {
  final CourtBlockRepository repository;
  final DateTime Function() _clock;

  LoadCourtBlocksUseCase(
    this.repository, {
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  Future<Either<Failure, List<CourtBlock>>> call(int courtId) {
    final now = _clock();

    return repository.loadBlocks(
      courtId,
      from: DateTime(now.year, now.month, now.day),
    );
  }
}
