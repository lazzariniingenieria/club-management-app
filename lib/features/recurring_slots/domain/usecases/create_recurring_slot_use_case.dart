import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/recurring_slot.dart';
import '../entities/recurring_slot_draft.dart';
import '../repositories/recurring_slot_repository.dart';

class CreateRecurringSlotUseCase {
  final RecurringSlotRepository repository;

  CreateRecurringSlotUseCase(this.repository);

  Future<Either<Failure, RecurringSlot>> call(RecurringSlotDraft draft) async {
    if (!draft.isValid) {
      return const Left(ValidationFailure('Invalid recurring slot'));
    }

    final created = await repository.createRecurringSlot(draft);
    if (created.getLeft().toNullable() is! ResponseTimeoutFailure) {
      return created;
    }

    return await findListed(repository, draft) ?? created;
  }

  static Future<Either<Failure, RecurringSlot>?> findListed(
    RecurringSlotRepository repository,
    RecurringSlotDraft draft,
  ) async {
    final listed = await repository.loadRecurringSlots();
    final slots = listed.getRight().toNullable() ?? const <RecurringSlot>[];

    for (final slot in slots) {
      if (draft.describes(slot)) return Right(slot);
    }

    return null;
  }
}
