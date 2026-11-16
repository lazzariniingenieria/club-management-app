import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../courts/domain/entities/court.dart';
import '../../../courts/domain/repositories/court_repository.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../entities/recurring_slot.dart';
import '../entities/recurring_slot_overview.dart';
import '../repositories/recurring_slot_repository.dart';

class LoadRecurringSlotOverviewUseCase {
  final RecurringSlotRepository recurringSlots;
  final CourtRepository courts;
  final MemberRepository members;

  LoadRecurringSlotOverviewUseCase({
    required this.recurringSlots,
    required this.courts,
    required this.members,
  });

  Future<Either<Failure, RecurringSlotOverview>> call() async {
    final results = await Future.wait<Object>([
      recurringSlots.loadRecurringSlots(),
      courts.loadCourts(),
      members.loadMembers(),
    ]);
    final slots = results[0] as Either<Failure, List<RecurringSlot>>;
    final courtList = results[1] as Either<Failure, List<Court>>;
    final roster = results[2] as Either<Failure, List<Member>>;

    return slots.flatMap(
      (slots) => courtList.flatMap(
        (courtList) => roster.map(
          (roster) => RecurringSlotOverview(
            slots: slots,
            courts: courtList,
            members: roster,
          ),
        ),
      ),
    );
  }
}
