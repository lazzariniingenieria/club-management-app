import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court.dart';
import 'package:club_management_app/features/reservations/domain/entities/day_agenda.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

final today = DateTime(2026, 11, 13);

Court court(int id) => Court(
      id: id,
      name: 'Cancha $id',
      openingTime: const ClockTime(8, 0),
      closingTime: const ClockTime(23, 0),
      isActive: true,
    );

Reservation at(int id, int courtId, int hour) => Reservation(
      id: id,
      courtId: courtId,
      memberId: 1,
      date: today,
      startTime: ClockTime(hour, 0),
      endTime: ClockTime(hour + 1, 0),
    );

DayAgenda agendaWith(List<Reservation> first, List<Reservation> second) {
  return DayAgenda(
    day: today,
    members: const [],
    courts: [
      CourtAgenda(court: court(1), reservations: first, blocks: const []),
      CourtAgenda(court: court(2), reservations: second, blocks: const []),
    ],
  );
}

void main() {
  test('lists the ones not finished yet, across courts, by start', () {
    final agenda = agendaWith(
      [at(1, 1, 9), at(2, 1, 18)],
      [at(3, 2, 10), at(4, 2, 20)],
    );

    final upcoming = agenda.upcoming(
      DateTime(2026, 11, 13, 10, 30),
      limit: 3,
    );

    expect(
      [for (final item in upcoming) item.reservation.id],
      [3, 2, 4],
    );
    expect(upcoming.first.court.id, 2);
  });

  test('keeps only the first ones up to the limit', () {
    final agenda = agendaWith(
      [at(1, 1, 9), at(2, 1, 11)],
      [at(3, 2, 12), at(4, 2, 13)],
    );

    final upcoming = agenda.upcoming(DateTime(2026, 11, 13, 8), limit: 3);

    expect(
      [for (final item in upcoming) item.reservation.id],
      [1, 2, 3],
    );
  });

  test('is empty once the last one ended', () {
    final agenda = agendaWith([at(1, 1, 9)], const []);

    expect(
      agenda.upcoming(DateTime(2026, 11, 13, 10), limit: 3),
      isEmpty,
    );
  });
}
