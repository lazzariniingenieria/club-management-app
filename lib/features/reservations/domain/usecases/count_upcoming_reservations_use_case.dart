import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/reservation_repository.dart';

class CountUpcomingReservationsUseCase {
  final ReservationRepository repository;

  CountUpcomingReservationsUseCase(this.repository);

  Future<Either<Failure, int>> call(int courtId) async {
    final result = await repository.loadUpcoming(courtId);

    return result.map((upcoming) => upcoming.length);
  }
}
