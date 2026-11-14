import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/recurring_slot_repository.dart';

class DeactivateRecurringSlotUseCase {
  final RecurringSlotRepository repository;

  DeactivateRecurringSlotUseCase(this.repository);

  Future<Either<Failure, void>> call(int recurringSlotId) async {
    final result = await repository.deactivateRecurringSlot(recurringSlotId);
    final alreadyInactive = result.getLeft().toNullable() is ConflictFailure;

    return alreadyInactive ? const Right(null) : result;
  }
}
