import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/reservations/data/datasources/reservation_fake_data_source.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 9, 10);
  final tomorrow = DateTime(2026, 11, 10);
  late ReservationFakeDataSource source;

  setUp(() {
    source = ReservationFakeDataSource(
      latency: Duration.zero,
      clock: () => now,
    );
  });

  test('cancelling twice is a conflict, like the API', () async {
    await source.cancelReservation(
      ReservationFakeDataSource.seededReservationId,
    );

    expect(
      () => source.cancelReservation(
        ReservationFakeDataSource.seededReservationId,
      ),
      throwsA(isA<ConflictException>()),
    );
  });

  test('an overlapping reservation of the same court is a conflict', () {
    expect(
      () => source.createReservation(
        ReservationDraft(
          courtId: ReservationFakeDataSource.seededCourtId,
          memberId: 1,
          date: tomorrow,
          startTime: const ClockTime(19, 30),
          endTime: const ClockTime(20, 30),
        ),
      ),
      throwsA(isA<ConflictException>()),
    );
  });

  test('lists only the reservations of the requested day', () async {
    expect(await source.fetchReservations(tomorrow), hasLength(1));
    expect(await source.fetchReservations(DateTime(2026, 11, 9)), isEmpty);
  });

  test('deactivating the court cancels its upcoming reservations', () async {
    source.cancelUpcomingOf(ReservationFakeDataSource.seededCourtId);

    expect(await source.fetchReservations(tomorrow), isEmpty);
  });
}
