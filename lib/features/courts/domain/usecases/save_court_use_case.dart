import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/court_draft.dart';
import '../repositories/court_repository.dart';

class SaveCourtUseCase {
  final CourtRepository repository;

  SaveCourtUseCase(this.repository);

  Future<Either<Failure, void>> create(CourtDraft draft) {
    if (!draft.closesAfterOpening) return Future.value(_invalidHours);

    return repository.createCourt(draft.trimmed());
  }

  Future<Either<Failure, void>> update(int courtId, CourtDraft draft) {
    if (!draft.closesAfterOpening) return Future.value(_invalidHours);

    return repository.updateCourt(courtId, draft.trimmed());
  }

  static const Either<Failure, void> _invalidHours =
      Left(ValidationFailure('Closing time must be after opening time'));
}
