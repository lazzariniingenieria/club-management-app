import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/clock_time.dart';
import '../../../courts/domain/entities/court_block_draft.dart';
import 'day_agenda.dart';
import 'reservation.dart';

enum SlotUnavailability { past, reserved, recurring, activity, blocked }

class StartOption extends Equatable {
  final ClockTime start;
  final SlotUnavailability? unavailability;

  const StartOption(this.start, {this.unavailability});

  bool get isAvailable => unavailability == null;

  @override
  List<Object?> get props => [start, unavailability];
}

class SlotRules {
  final CourtAgenda agenda;
  final DateTime day;
  final DateTime now;

  const SlotRules({required this.agenda, required this.day, required this.now});

  static const int stepMinutes = 30;
  static const int defaultDurationMinutes = 60;
  static const List<int> durationsInMinutes = [
    defaultDurationMinutes,
    90,
    120,
  ];

  static ClockTime endFor(ClockTime start, int durationMinutes) =>
      _clockTime(start.minutesOfDay + durationMinutes);

  List<StartOption> startOptions(int durationMinutes) {
    final opening = agenda.court.openingTime.minutesOfDay;
    final closing = agenda.court.closingTime.minutesOfDay;

    return [
      for (var minutes = opening;
          minutes + durationMinutes <= closing;
          minutes += stepMinutes)
        StartOption(
          _clockTime(minutes),
          unavailability:
              _why(_clockTime(minutes), _clockTime(minutes + durationMinutes)),
        ),
    ];
  }

  SlotUnavailability? _why(ClockTime start, ClockTime end) {
    final startsAt = CourtBlockDraft.at(day, start);
    final endsAt = CourtBlockDraft.at(day, end);

    if (startsAt.isBefore(now)) return SlotUnavailability.past;
    for (final reservation in agenda.reservations) {
      if (reservation.overlaps(start, end)) return _takenBy(reservation);
    }

    final blocked = agenda.blocks.any(
      (block) =>
          block.startsAt.isBefore(endsAt) && block.endsAt.isAfter(startsAt),
    );

    return blocked ? SlotUnavailability.blocked : null;
  }

  static SlotUnavailability _takenBy(Reservation reservation) =>
      switch (reservation.source) {
        ReservationSource.member => SlotUnavailability.reserved,
        ReservationSource.recurring => SlotUnavailability.recurring,
        ReservationSource.activity => SlotUnavailability.activity,
      };

  static ClockTime _clockTime(int minutesOfDay) => ClockTime(
        minutesOfDay ~/ Duration.minutesPerHour,
        minutesOfDay % Duration.minutesPerHour,
      );
}
