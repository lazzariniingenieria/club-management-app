import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/clock_time.dart';

class Reservation extends Equatable {
  final int id;
  final int courtId;
  final int? memberId;
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
  });

  bool overlaps(ClockTime start, ClockTime end) =>
      startTime.compareTo(end) < 0 && endTime.compareTo(start) > 0;

  @override
  List<Object?> get props => [id, courtId, memberId, date, startTime, endTime];
}
