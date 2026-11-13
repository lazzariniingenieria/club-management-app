import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/court.dart';
import '../entities/court_draft.dart';

abstract class CourtRepository {
  Stream<void> get courtChanges;

  Future<Either<Failure, List<Court>>> loadCourts();

  Future<Either<Failure, void>> createCourt(CourtDraft draft);

  Future<Either<Failure, void>> updateCourt(int courtId, CourtDraft draft);

  Future<Either<Failure, void>> setCourtActive(
    int courtId, {
    required bool isActive,
  });
}
