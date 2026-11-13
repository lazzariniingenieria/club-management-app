import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/reservation_draft.dart';
import '../repositories/reservation_repository.dart';

class CreateReservationUseCase {
  final ReservationRepository repository;

  CreateReservationUseCase(this.repository);

  Future<Either<Failure, void>> call(ReservationDraft draft) async {
    if (!draft.endsAfterStarts) {
      return const Left(ValidationFailure('Invalid reservation'));
    }

    final created = await repository.createReservation(draft);
    if (!_mayAlreadyExist(created.getLeft().toNullable())) return created;

    return await _isListed(draft) ? const Right(null) : created;
  }

  static bool _mayAlreadyExist(Failure? failure) =>
      failure is ResponseTimeoutFailure || failure is ConflictFailure;

  Future<bool> _isListed(ReservationDraft draft) async {
    final listed = await repository.loadReservations(draft.date);

    return listed.fold((_) => false, (all) => all.any(draft.describes));
  }
}
