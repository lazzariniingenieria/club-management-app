import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/clock_time.dart';
import 'recurring_slot.dart';
import 'recurring_slot_validity.dart';

class RecurringSlotDraft extends Equatable {
  final int courtId;
  final int? memberId;
  final String? description;
  final int weekday;
  final ClockTime startTime;
  final ClockTime endTime;
  final RecurringSlotValidity validity;

  const RecurringSlotDraft({
    required this.courtId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.validity,
    this.memberId,
    this.description,
  });

  static const int maxDescriptionLength = 100;

  bool get hasExactlyOneHolder => (memberId == null) != (_description == null);

  String? get _description {
    final trimmed = description?.trim();

    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  bool get isValid =>
      hasExactlyOneHolder &&
      (_description?.length ?? 0) <= maxDescriptionLength &&
      endTime.isAfter(startTime) &&
      validity.isWithinLimits;

  List<DateTime> dates(DateTime now) =>
      validity.datesOn(weekday, start: startTime, now: now);

  bool describes(RecurringSlot slot) =>
      slot.isActive &&
      slot.courtId == courtId &&
      slot.memberId == memberId &&
      slot.description == _description &&
      slot.weekday == weekday &&
      slot.startTime == startTime &&
      slot.endTime == endTime &&
      slot.validFrom == validity.from &&
      slot.validUntil == validity.until;

  @override
  List<Object?> get props => [
        courtId,
        memberId,
        _description,
        weekday,
        startTime,
        endTime,
        validity,
      ];
}
