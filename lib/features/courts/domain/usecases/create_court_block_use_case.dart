import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/court_block_draft.dart';
import '../repositories/court_block_repository.dart';
import '../validation/court_block_rules.dart';

class CreateCourtBlockUseCase {
  final CourtBlockRepository repository;

  CreateCourtBlockUseCase(this.repository);

  Future<Either<Failure, void>> call(int courtId, CourtBlockDraft draft) {
    if (!draft.endsAfterStarts || !CourtBlockRules.reasonFits(draft.reason)) {
      return Future.value(
        const Left(ValidationFailure('Invalid court block')),
      );
    }

    return repository.createBlock(courtId, draft.trimmed());
  }
}
