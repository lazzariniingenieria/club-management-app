import 'package:equatable/equatable.dart';

import 'clock_time.dart';
import 'court_block.dart';

class CourtBlockDraft extends Equatable {
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;
  final List<int> reservationIdsToCancel;

  const CourtBlockDraft({
    required this.startsAt,
    required this.endsAt,
    this.reason = '',
    this.reservationIdsToCancel = const [],
  });

  static DateTime at(DateTime day, ClockTime time) =>
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  bool get endsAfterStarts => endsAt.isAfter(startsAt);

  DateTime get firstDay =>
      DateTime(startsAt.year, startsAt.month, startsAt.day);

  bool describes(CourtBlock block) =>
      block.startsAt.isAtSameMomentAs(startsAt) &&
      block.endsAt.isAtSameMomentAs(endsAt) &&
      (block.reason ?? '') == reason;

  CourtBlockDraft trimmed() => CourtBlockDraft(
        startsAt: startsAt,
        endsAt: endsAt,
        reason: reason.trim(),
        reservationIdsToCancel: reservationIdsToCancel,
      );

  CourtBlockDraft cancelling(List<int> reservationIds) => CourtBlockDraft(
        startsAt: startsAt,
        endsAt: endsAt,
        reason: reason,
        reservationIdsToCancel: reservationIds,
      );

  bool overlaps(DateTime start, DateTime end) =>
      start.isBefore(endsAt) && end.isAfter(startsAt);

  @override
  List<Object?> get props => [startsAt, endsAt, reason, reservationIdsToCancel];
}
