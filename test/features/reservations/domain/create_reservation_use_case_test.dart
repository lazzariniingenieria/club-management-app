import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation_draft.dart';
import 'package:club_management_app/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:club_management_app/features/reservations/domain/usecases/create_reservation_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockReservationRepository extends Mock implements ReservationRepository {}

void main() {
  final day = DateTime(2026, 11, 10);
  final draft = ReservationDraft(
    courtId: 2,
    memberId: 7,
    date: day,
    startTime: const ClockTime(19, 0),
    endTime: const ClockTime(20, 0),
  );
  late MockReservationRepository repository;
  late CreateReservationUseCase createReservation;

  Reservation listedFor(int memberId) => Reservation(
        id: 40,
        courtId: 2,
        memberId: memberId,
        date: day,
        startTime: const ClockTime(19, 0),
        endTime: const ClockTime(20, 0),
      );

  void answerCreate(Failure failure) {
    when(() => repository.createReservation(draft))
        .thenAnswer((_) async => Left(failure));
  }

  void answerListed(List<Reservation> listed) {
    when(() => repository.loadReservations(day))
        .thenAnswer((_) async => Right(listed));
  }

  setUp(() {
    repository = MockReservationRepository();
    createReservation = CreateReservationUseCase(repository);
  });

  test('a timeout whose reservation was created counts as created', () async {
    answerCreate(const ResponseTimeoutFailure());
    answerListed([listedFor(7)]);

    final result = await createReservation(draft);

    expect(result.isRight(), isTrue);
  });

  test('a timeout whose reservation is not listed stays a timeout', () async {
    answerCreate(const ResponseTimeoutFailure());
    answerListed([]);

    final result = await createReservation(draft);

    expect(result.getLeft().toNullable(), isA<ResponseTimeoutFailure>());
  });

  test('a conflict with the same reservation, after a timeout, counts as '
      'created', () async {
    answerCreate(const ConflictFailure('court already reserved'));
    answerListed([listedFor(7)]);

    final result = await createReservation(draft);

    expect(result.isRight(), isTrue);
  });

  test('a conflict with another member stays a conflict', () async {
    answerCreate(const ConflictFailure('court already reserved'));
    answerListed([listedFor(8)]);

    final result = await createReservation(draft);

    expect(result.getLeft().toNullable(), isA<ConflictFailure>());
  });

  test('any other failure is returned without rereading', () async {
    answerCreate(const ValidationFailure('starts in the past'));

    final result = await createReservation(draft);

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.loadReservations(day));
  });
}
