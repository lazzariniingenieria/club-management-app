import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/reservation_draft.dart';
import '../repositories/reservation_repository.dart';

class CreateReservationUseCase {
  final ReservationRepository repository;

  CreateReservationUseCase(this.repository);

  Future<Either<Failure, void>> call(ReservationDraft draft) {
    if (!draft.endsAfterStarts) {
      return Future.value(const Left(ValidationFailure('Invalid reservation')));
    }

    return repository.createReservation(draft);
  }
}
