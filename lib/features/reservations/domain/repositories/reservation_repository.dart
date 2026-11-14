import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../courts/domain/entities/court_block_draft.dart';
import '../entities/reservation.dart';
import '../entities/reservation_draft.dart';

abstract class ReservationRepository {
  Stream<void> get reservationChanges;

  Future<Either<Failure, List<Reservation>>> loadReservations(DateTime day);

  Future<Either<Failure, List<Reservation>>> loadAffectedByBlock(
    int courtId,
    CourtBlockDraft block,
  );

  Future<Either<Failure, void>> createReservation(ReservationDraft draft);

  Future<Either<Failure, void>> cancelReservation(int reservationId);
}
