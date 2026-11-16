import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:club_management_app/features/reservations/presentation/formatting/reservation_formats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a reservation reads as its day and its hours', () {
    final reservation = Reservation(
      id: 1,
      courtId: 3,
      memberId: 1,
      date: DateTime(2026, 12, 2),
      startTime: const ClockTime(18, 0),
      endTime: const ClockTime(19, 0),
    );

    expect(
      ReservationFormats.dayAndHours(reservation),
      'mié 02/12/2026 · 18:00 a 19:00',
    );
  });
}
