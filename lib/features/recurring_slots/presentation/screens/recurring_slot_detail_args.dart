import '../../domain/entities/recurring_slot.dart';
import '../../domain/entities/recurring_slot_overview.dart';

class RecurringSlotDetailArgs {
  final RecurringSlot slot;
  final RecurringSlotOverview overview;

  const RecurringSlotDetailArgs({required this.slot, required this.overview});
}
