import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/recurring_slot.dart';
import '../entities/recurring_slot_draft.dart';
import '../entities/recurring_slot_validity.dart';

abstract class RecurringSlotRepository {
  Stream<void> get recurringSlotChanges;

  Future<Either<Failure, List<RecurringSlot>>> loadRecurringSlots();

  Future<Either<Failure, RecurringSlot>> createRecurringSlot(
    RecurringSlotDraft draft,
  );

  Future<Either<Failure, RecurringSlot>> renewRecurringSlot(
    int recurringSlotId,
    RecurringSlotValidity validity,
  );

  Future<Either<Failure, void>> deactivateRecurringSlot(int recurringSlotId);
}
