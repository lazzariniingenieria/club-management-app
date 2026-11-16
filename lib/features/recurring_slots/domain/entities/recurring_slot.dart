import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/clock_time.dart';

enum RecurringSlotState { current, expired, inactive }

class RecurringSlot extends Equatable {
  final int id;
  final int courtId;
  final int? memberId;
  final String? description;
  final int weekday;
  final ClockTime startTime;
  final ClockTime endTime;
  final DateTime validFrom;
  final DateTime validUntil;
  final RecurringSlotState state;

  const RecurringSlot({
    required this.id,
    required this.courtId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.validFrom,
    required this.validUntil,
    required this.state,
    this.memberId,
    this.description,
  });

  bool get isActivity => memberId == null;

  bool get isActive => state != RecurringSlotState.inactive;

  int daysUntilExpiry(DateTime today) =>
      _dayOf(validUntil).difference(_dayOf(today)).inDays;

  static DateTime _dayOf(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  @override
  List<Object?> get props => [
        id,
        courtId,
        memberId,
        description,
        weekday,
        startTime,
        endTime,
        validFrom,
        validUntil,
        state,
      ];
}
