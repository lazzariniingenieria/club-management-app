import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/court_repository.dart';

class SetCourtActiveUseCase {
  final CourtRepository repository;

  SetCourtActiveUseCase(this.repository);

  Future<Either<Failure, void>> call(int courtId, {required bool isActive}) =>
      repository.setCourtActive(courtId, isActive: isActive);
}
