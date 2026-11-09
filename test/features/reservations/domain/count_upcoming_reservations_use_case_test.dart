import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:club_management_app/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:club_management_app/features/reservations/domain/usecases/count_upcoming_reservations_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockReservationRepository extends Mock implements ReservationRepository {}

void main() {
  late MockReservationRepository repository;

  setUp(() => repository = MockReservationRepository());

  test('counts the upcoming reservations of the court', () async {
    when(() => repository.loadUpcoming(3)).thenAnswer(
      (_) async => Right([
        for (var id = 1; id <= 2; id++)
          Reservation(
            id: id,
            courtId: 3,
            memberId: 1,
            date: DateTime(2026, 11, 10),
            startTime: ClockTime(8 + id, 0),
            endTime: ClockTime(9 + id, 0),
          ),
      ]),
    );

    final result = await CountUpcomingReservationsUseCase(repository)(3);

    expect(result.getRight().toNullable(), 2);
  });

  test('a failure is reported so the warning can stay generic', () async {
    when(() => repository.loadUpcoming(3))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await CountUpcomingReservationsUseCase(repository)(3);

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
  });
}
