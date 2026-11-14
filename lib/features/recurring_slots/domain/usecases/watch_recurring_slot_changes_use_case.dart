import '../repositories/recurring_slot_repository.dart';

class WatchRecurringSlotChangesUseCase {
  final RecurringSlotRepository repository;

  WatchRecurringSlotChangesUseCase(this.repository);

  Stream<void> call() => repository.recurringSlotChanges;
}
