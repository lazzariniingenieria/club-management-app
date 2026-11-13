import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/clock_time.dart';
import 'reservation.dart';

class ReservationDraft extends Equatable {
  final int courtId;
  final int memberId;
  final DateTime date;
  final ClockTime startTime;
  final ClockTime endTime;

  const ReservationDraft({
    required this.courtId,
    required this.memberId,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  bool get endsAfterStarts => endTime.isAfter(startTime);

  bool describes(Reservation reservation) =>
      reservation.courtId == courtId &&
      reservation.memberId == memberId &&
      _sameDay(reservation.date, date) &&
      reservation.startTime == startTime &&
      reservation.endTime == endTime;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  List<Object?> get props => [courtId, memberId, date, startTime, endTime];
}
