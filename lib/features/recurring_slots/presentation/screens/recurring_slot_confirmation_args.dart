import '../../../courts/domain/entities/court.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/recurring_slot_draft.dart';

class RecurringSlotConfirmationArgs {
  final RecurringSlotDraft draft;
  final Court court;
  final Member? member;

  const RecurringSlotConfirmationArgs({
    required this.draft,
    required this.court,
    this.member,
  });
}
