import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/court.dart';
import '../../../members/domain/entities/member.dart';
import 'recurring_slot.dart';

class RecurringSlotOverview extends Equatable {
  final List<RecurringSlot> slots;
  final List<Court> courts;
  final List<Member> members;

  const RecurringSlotOverview({
    required this.slots,
    required this.courts,
    required this.members,
  });

  Court? courtOf(RecurringSlot slot) {
    for (final court in courts) {
      if (court.id == slot.courtId) return court;
    }

    return null;
  }

  Member? memberOf(RecurringSlot slot) {
    for (final member in members) {
      if (member.id == slot.memberId) return member;
    }

    return null;
  }

  List<Court> get activeCourts => [
        for (final court in courts)
          if (court.isActive) court,
      ];

  List<RecurringSlot> inState(RecurringSlotState state) => [
        for (final slot in slots)
          if (slot.state == state) slot,
      ];

  @override
  List<Object?> get props => [slots, courts, members];
}
