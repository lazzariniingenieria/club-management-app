import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/reservations/data/models/reservation_model.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a reservation as the API sends it', () {
    final reservation = ReservationModel.fromJson(const {
      'id': 20,
      'courtId': 3,
      'memberId': 10,
      'source': 'MEMBER',
      'date': '2026-11-09',
      'startTime': '22:00:00',
      'endTime': '23:00:00',
      'status': 'CONFIRMED',
    });

    expect(reservation.date, DateTime(2026, 11, 9));
    expect(reservation.startTime, const ClockTime(22, 0));
    expect(reservation.memberId, 10);
  });

  test('an activity of the club has no member', () {
    final reservation = ReservationModel.fromJson(const {
      'id': 21,
      'courtId': 3,
      'memberId': null,
      'date': '2026-11-09',
      'startTime': '17:00:00',
      'endTime': '18:00:00',
    });

    expect(reservation.memberId, isNull);
  });

  test('sends the day and the hours without seconds', () {
    final body = ReservationModel.bodyFromDraft(
      ReservationDraft(
        courtId: 3,
        memberId: 10,
        date: DateTime(2026, 11, 9),
        startTime: const ClockTime(8, 30),
        endTime: const ClockTime(10, 0),
      ),
    );

    expect(body, {
      'courtId': 3,
      'memberId': 10,
      'date': '2026-11-09',
      'startTime': '08:30',
      'endTime': '10:00',
    });
  });
}
