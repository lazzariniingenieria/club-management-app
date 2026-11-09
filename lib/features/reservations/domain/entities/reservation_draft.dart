import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/clock_time.dart';

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

  @override
  List<Object?> get props => [courtId, memberId, date, startTime, endTime];
}
