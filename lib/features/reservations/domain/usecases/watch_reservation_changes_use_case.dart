import '../repositories/reservation_repository.dart';

class WatchReservationChangesUseCase {
  final ReservationRepository repository;

  WatchReservationChangesUseCase(this.repository);

  Stream<void> call() => repository.reservationChanges;
}
