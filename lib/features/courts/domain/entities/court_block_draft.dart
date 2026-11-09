import 'package:equatable/equatable.dart';

import 'clock_time.dart';

class CourtBlockDraft extends Equatable {
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;

  const CourtBlockDraft({
    required this.startsAt,
    required this.endsAt,
    this.reason = '',
  });

  static DateTime at(DateTime day, ClockTime time) =>
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  bool get endsAfterStarts => endsAt.isAfter(startsAt);

  CourtBlockDraft trimmed() => CourtBlockDraft(
        startsAt: startsAt,
        endsAt: endsAt,
        reason: reason.trim(),
      );

  @override
  List<Object?> get props => [startsAt, endsAt, reason];
}
