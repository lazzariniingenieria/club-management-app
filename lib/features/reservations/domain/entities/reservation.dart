import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/clock_time.dart';

enum ReservationSource { member, recurring, activity }

class Reservation extends Equatable {
  final int id;
  final int courtId;
  final int? memberId;
  final ReservationSource source;
  final int? recurringSlotId;
  final String? description;
  final DateTime date;
  final ClockTime startTime;
  final ClockTime endTime;

  const Reservation({
    required this.id,
    required this.courtId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.memberId,
    this.source = ReservationSource.member,
    this.recurringSlotId,
    this.description,
  });

  bool get isOneOff => source == ReservationSource.member;

  bool overlaps(ClockTime start, ClockTime end) =>
      startTime.compareTo(end) < 0 && endTime.compareTo(start) > 0;

  @override
  List<Object?> get props => [
        id,
        courtId,
        memberId,
        source,
        recurringSlotId,
        description,
        date,
        startTime,
        endTime,
      ];
}
