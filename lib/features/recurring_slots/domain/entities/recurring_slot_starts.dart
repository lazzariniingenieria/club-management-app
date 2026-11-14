import '../../../courts/domain/entities/clock_time.dart';
import '../../../courts/domain/entities/court.dart';
import '../../../reservations/domain/entities/start_option.dart';

abstract final class RecurringSlotStarts {
  static List<ClockTime> of(Court court, int durationMinutes) {
    final closing = court.closingTime.minutesOfDay;

    return [
      for (var minutes = court.openingTime.minutesOfDay;
          minutes + durationMinutes <= closing;
          minutes += SlotRules.stepMinutes)
        ClockTime(
          minutes ~/ Duration.minutesPerHour,
          minutes % Duration.minutesPerHour,
        ),
    ];
  }
}
