import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court.dart';
import 'package:club_management_app/features/courts/domain/entities/court_block.dart';
import 'package:club_management_app/features/reservations/domain/entities/day_agenda.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:club_management_app/features/reservations/domain/entities/start_option.dart';
import 'package:flutter_test/flutter_test.dart';

final day = DateTime(2026, 11, 10);
final yesterday = DateTime(2026, 11, 9, 12);

const court = Court(
  id: 2,
  name: 'Cancha de Tenis 1',
  openingTime: ClockTime(8, 0),
  closingTime: ClockTime(11, 0),
  isActive: true,
);

Reservation reservation(int hour, int endHour) => Reservation(
      id: hour,
      courtId: 2,
      memberId: 1,
      date: day,
      startTime: ClockTime(hour, 0),
      endTime: ClockTime(endHour, 0),
    );

SlotRules rules({
  List<Reservation> reservations = const [],
  List<CourtBlock> blocks = const [],
  DateTime? now,
}) {
  return SlotRules(
    agenda: CourtAgenda(
      court: court,
      reservations: reservations,
      blocks: blocks,
    ),
    day: day,
    now: now ?? yesterday,
  );
}

void main() {
  test('offers a start every half hour that still fits before closing', () {
    final starts = rules().startOptions(60).map((option) => option.start);

    expect(starts, const [
      ClockTime(8, 0),
      ClockTime(8, 30),
      ClockTime(9, 0),
      ClockTime(9, 30),
      ClockTime(10, 0),
    ]);
  });

  test('a longer reservation has fewer starts', () {
    expect(rules().startOptions(120), hasLength(3));
  });

  test('marks the starts that overlap a reservation as reserved', () {
    final options = rules(reservations: [reservation(9, 10)]).startOptions(60);
    final reasons = {
      for (final option in options) option.start: option.unavailability,
    };

    expect(reasons[const ClockTime(8, 0)], isNull);
    expect(reasons[const ClockTime(8, 30)], SlotUnavailability.reserved);
    expect(reasons[const ClockTime(9, 30)], SlotUnavailability.reserved);
    expect(reasons[const ClockTime(10, 0)], isNull);
  });

  test('marks the starts that fall in a block as blocked', () {
    final block = CourtBlock(
      id: 1,
      courtId: 2,
      startsAt: DateTime(2026, 11, 9, 20),
      endsAt: DateTime(2026, 11, 10, 9),
    );

    final options = rules(blocks: [block]).startOptions(60);

    expect(options.first.unavailability, SlotUnavailability.blocked);
    expect(options[2].isAvailable, isTrue);
  });

  test('marks the starts that already passed as past', () {
    final options =
        rules(now: DateTime(2026, 11, 10, 9, 15)).startOptions(60);

    expect(options[2].unavailability, SlotUnavailability.past);
    expect(options[3].isAvailable, isTrue);
  });

  test('computes the end of a reservation from its duration', () {
    expect(
      SlotRules.endFor(const ClockTime(21, 30), 90),
      const ClockTime(23, 0),
    );
  });
}
