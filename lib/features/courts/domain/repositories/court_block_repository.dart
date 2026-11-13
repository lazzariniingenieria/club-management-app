import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/court_block.dart';
import '../entities/court_block_draft.dart';

abstract class CourtBlockRepository {
  Stream<void> get blockChanges;

  Future<Either<Failure, List<CourtBlock>>> loadBlocks(
    int courtId, {
    required DateTime from,
  });

  Future<Either<Failure, void>> createBlock(
    int courtId,
    CourtBlockDraft draft,
  );

  Future<Either<Failure, void>> removeBlock(int courtId, int blockId);
}
