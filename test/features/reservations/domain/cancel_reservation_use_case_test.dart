import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:club_management_app/features/reservations/domain/usecases/cancel_reservation_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockReservationRepository extends Mock implements ReservationRepository {}

void main() {
  late MockReservationRepository repository;

  setUp(() => repository = MockReservationRepository());

  test('a reservation someone else already cancelled counts as cancelled',
      () async {
    when(() => repository.cancelReservation(20))
        .thenAnswer((_) async => const Left(ConflictFailure()));

    final result = await CancelReservationUseCase(repository)(20);

    expect(result.isRight(), isTrue);
  });

  test('any other failure is reported', () async {
    when(() => repository.cancelReservation(20))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await CancelReservationUseCase(repository)(20);

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
  });
}
