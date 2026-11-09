import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/reservation_repository.dart';

class CancelReservationUseCase {
  final ReservationRepository repository;

  CancelReservationUseCase(this.repository);

  Future<Either<Failure, void>> call(int reservationId) async {
    final result = await repository.cancelReservation(reservationId);
    final alreadyCancelled =
        result.getLeft().toNullable() is ConflictFailure;

    return alreadyCancelled ? const Right(null) : result;
  }
}
