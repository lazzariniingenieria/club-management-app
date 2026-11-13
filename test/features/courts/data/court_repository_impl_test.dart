import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/features/courts/data/datasources/court_fake_data_source.dart';
import 'package:club_management_app/features/courts/data/repositories/court_repository_impl.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court_draft.dart';
import 'package:flutter_test/flutter_test.dart';

class UnansweredCreations extends CourtFakeDataSource {
  UnansweredCreations() : super(latency: Duration.zero);

  @override
  Future<void> createCourt(CourtDraft draft) =>
      throw ResponseTimeoutException('no answer');
}

class SilentLogger implements AppLogger {
  const SilentLogger();

  @override
  void info(String message, {String? context}) {}

  @override
  void warning(String message, {String? context}) {}

  @override
  void error(String message,
      {String? context, Object? cause, StackTrace? stackTrace}) {}
}

void main() {
  late CourtRepositoryImpl repository;
  late List<void> announcements;

  const newCourt = CourtDraft(name: 'Cancha de Pádel 2');
  final seeded = CourtFakeDataSource.seeded.first;

  void listenTo(CourtFakeDataSource source) {
    repository = CourtRepositoryImpl(
      remoteDataSource: source,
      logger: const SilentLogger(),
    );
    announcements = [];
    repository.courtChanges.listen(announcements.add);
  }

  setUp(() => listenTo(CourtFakeDataSource(latency: Duration.zero)));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a created court is announced', () async {
    await repository.createCourt(newCourt);
    await settle();

    expect(announcements, hasLength(1));
  });

  test('a court deactivated and reactivated is announced twice', () async {
    await repository.setCourtActive(seeded.id, isActive: false);
    await repository.setCourtActive(seeded.id, isActive: true);
    await settle();

    expect(announcements, hasLength(2));
  });

  test('a timed out creation announces, it may have gone through', () async {
    listenTo(UnansweredCreations());

    final result = await repository.createCourt(newCourt);
    await settle();

    expect(result.getLeft().toNullable(), isA<ResponseTimeoutFailure>());
    expect(announcements, hasLength(1));
  });

  test('a repeated name announces, the list on screen is out of date',
      () async {
    final result = await repository.createCourt(
      CourtDraft(name: seeded.name),
    );
    await settle();

    expect(result.getLeft().toNullable(), isA<ConflictFailure>());
    expect(announcements, hasLength(1));
  });

  test('a rejected court announces nothing, the courts did not change',
      () async {
    const closesBeforeOpening = CourtDraft(
      name: 'Cancha de Pádel 2',
      openingTime: ClockTime(23, 0),
      closingTime: ClockTime(8, 0),
    );

    final result = await repository.createCourt(closesBeforeOpening);
    await settle();

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    expect(announcements, isEmpty);
  });

  test('reading the courts announces nothing', () async {
    await repository.loadCourts();
    await settle();

    expect(announcements, isEmpty);
  });
}
