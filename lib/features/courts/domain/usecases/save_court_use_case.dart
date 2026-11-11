import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/court_draft.dart';
import '../repositories/court_repository.dart';

class SaveCourtUseCase {
  final CourtRepository repository;

  SaveCourtUseCase(this.repository);

  Future<Either<Failure, void>> create(
    CourtDraft draft, {
    bool retriesUnconfirmed = false,
  }) async {
    if (!draft.closesAfterOpening) return _invalidHours;

    final created = await repository.createCourt(draft.trimmed());
    final failure = created.getLeft().toNullable();
    final mayBeCreated = failure is ResponseTimeoutFailure ||
        (retriesUnconfirmed && failure is ConflictFailure);
    if (!mayBeCreated) return created;

    return await _isListed(draft) ? const Right(null) : created;
  }

  Future<Either<Failure, void>> update(int courtId, CourtDraft draft) {
    if (!draft.closesAfterOpening) return Future.value(_invalidHours);

    return repository.updateCourt(courtId, draft.trimmed());
  }

  Future<bool> _isListed(CourtDraft draft) async {
    final courts = await repository.loadCourts();

    return courts.fold(
      (_) => false,
      (listed) => listed.any(
        (court) => court.name.toLowerCase() == draft.nameAsCompared,
      ),
    );
  }

  static const Either<Failure, void> _invalidHours =
      Left(ValidationFailure('Closing time must be after opening time'));
}
