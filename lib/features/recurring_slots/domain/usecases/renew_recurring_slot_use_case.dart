import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/recurring_slot.dart';
import '../entities/recurring_slot_draft.dart';
import '../entities/recurring_slot_validity.dart';
import '../repositories/recurring_slot_repository.dart';
import 'create_recurring_slot_use_case.dart';

class RenewRecurringSlotUseCase {
  final RecurringSlotRepository repository;

  RenewRecurringSlotUseCase(this.repository);

  Future<Either<Failure, RecurringSlot>> call(
    RecurringSlot original,
    RecurringSlotValidity validity,
  ) async {
    if (!validity.isWithinLimits) {
      return const Left(ValidationFailure('Invalid validity'));
    }

    final renewed = await repository.renewRecurringSlot(original.id, validity);
    if (renewed.getLeft().toNullable() is! ResponseTimeoutFailure) {
      return renewed;
    }

    return await CreateRecurringSlotUseCase.findListed(
          repository,
          _renewalOf(original, validity),
        ) ??
        renewed;
  }

  static RecurringSlotDraft _renewalOf(
    RecurringSlot original,
    RecurringSlotValidity validity,
  ) {
    return RecurringSlotDraft(
      courtId: original.courtId,
      memberId: original.memberId,
      description: original.description,
      weekday: original.weekday,
      startTime: original.startTime,
      endTime: original.endTime,
      validity: validity,
    );
  }
}
