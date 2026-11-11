import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/court_block_draft.dart';
import '../repositories/court_block_repository.dart';
import '../validation/court_block_rules.dart';

class CreateCourtBlockUseCase {
  final CourtBlockRepository repository;

  CreateCourtBlockUseCase(this.repository);

  Future<Either<Failure, void>> call(int courtId, CourtBlockDraft draft) async {
    if (!draft.endsAfterStarts || !CourtBlockRules.reasonFits(draft.reason)) {
      return const Left(ValidationFailure('Invalid court block'));
    }

    final block = draft.trimmed();
    final created = await repository.createBlock(courtId, block);
    final timedOut = created.getLeft().toNullable() is ResponseTimeoutFailure;
    if (!timedOut) return created;

    return await _isListed(courtId, block) ? const Right(null) : created;
  }

  Future<bool> _isListed(int courtId, CourtBlockDraft block) async {
    final blocks = await repository.loadBlocks(courtId, from: block.firstDay);

    return blocks.fold((_) => false, (listed) => listed.any(block.describes));
  }
}
