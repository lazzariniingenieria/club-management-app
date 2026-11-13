import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court.dart';
import 'package:club_management_app/features/courts/domain/entities/court_draft.dart';
import 'package:club_management_app/features/courts/domain/repositories/court_repository.dart';
import 'package:club_management_app/features/courts/domain/usecases/save_court_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCourtRepository extends Mock implements CourtRepository {}

void main() {
  late MockCourtRepository repository;
  late SaveCourtUseCase saveCourt;

  setUpAll(() => registerFallbackValue(const CourtDraft(name: '')));

  setUp(() {
    repository = MockCourtRepository();
    saveCourt = SaveCourtUseCase(repository);
  });

  group('a creation that got no answer or a repeated name', () {
    const draft = CourtDraft(name: 'Cancha 1');
    const listedCourt = Court(
      id: 7,
      name: 'CANCHA 1',
      openingTime: ClockTime(8, 0),
      closingTime: ClockTime(23, 0),
      isActive: true,
    );

    void creationAnswers(Failure failure) {
      when(() => repository.createCourt(draft))
          .thenAnswer((_) async => Left(failure));
    }

    void courtsAre(Either<Failure, List<Court>> courts) {
      when(() => repository.loadCourts()).thenAnswer((_) async => courts);
    }

    test('a timeout whose court went through counts as created', () async {
      creationAnswers(const ResponseTimeoutFailure());
      courtsAre(const Right([listedCourt]));

      final result = await saveCourt.create(draft);

      expect(result.isRight(), isTrue);
      verify(() => repository.createCourt(draft)).called(1);
    });

    test('a timeout whose court did not go through is reported', () async {
      creationAnswers(const ResponseTimeoutFailure());
      courtsAre(const Right([]));

      final result = await saveCourt.create(draft);

      expect(result.getLeft().toNullable(), const ResponseTimeoutFailure());
    });

    test('a timeout that could not be checked is reported', () async {
      creationAnswers(const ResponseTimeoutFailure());
      courtsAre(const Left(NetworkFailure()));

      final result = await saveCourt.create(draft);

      expect(result.getLeft().toNullable(), const ResponseTimeoutFailure());
    });

    test('a repeated name after an unconfirmed creation is the court sent',
        () async {
      creationAnswers(const ConflictFailure());

      final result = await saveCourt.create(draft, retriesUnconfirmed: true);

      expect(result.isRight(), isTrue);
      verifyNever(() => repository.loadCourts());
    });

    test('a repeated name with nothing unconfirmed stays a conflict', () async {
      creationAnswers(const ConflictFailure());

      final result = await saveCourt.create(draft);

      expect(result.getLeft().toNullable(), const ConflictFailure());
      verifyNever(() => repository.loadCourts());
    });
  });

  test('trims the name and the sport before creating', () async {
    const trimmed = CourtDraft(name: 'Cancha 1', type: 'Pádel');
    when(() => repository.createCourt(trimmed))
        .thenAnswer((_) async => const Right(null));

    final result = await saveCourt.create(
      const CourtDraft(name: '  Cancha 1 ', type: ' Pádel  '),
    );

    expect(result.isRight(), isTrue);
    verify(() => repository.createCourt(trimmed)).called(1);
  });

  test('a court that closes before it opens is never sent', () async {
    final result = await saveCourt.create(
      const CourtDraft(
        name: 'Cancha 1',
        openingTime: ClockTime(23, 0),
        closingTime: ClockTime(8, 0),
      ),
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.createCourt(any()));
  });

  test('a court that closes when it opens is not updated', () async {
    final result = await saveCourt.update(
      3,
      const CourtDraft(
        name: 'Cancha 1',
        openingTime: ClockTime(9, 0),
        closingTime: ClockTime(9, 0),
      ),
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.updateCourt(any(), any()));
  });

  test('updates the court with the trimmed draft', () async {
    const trimmed = CourtDraft(name: 'Cancha 2');
    when(() => repository.updateCourt(3, trimmed))
        .thenAnswer((_) async => const Right(null));

    await saveCourt.update(3, const CourtDraft(name: 'Cancha 2 '));

    verify(() => repository.updateCourt(3, trimmed)).called(1);
  });
}
