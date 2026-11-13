import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/features/courts/data/datasources/court_block_fake_data_source.dart';
import 'package:club_management_app/features/courts/data/repositories/court_block_repository_impl.dart';
import 'package:club_management_app/features/courts/domain/entities/court_block_draft.dart';
import 'package:flutter_test/flutter_test.dart';

class UnansweredCreations extends CourtBlockFakeDataSource {
  UnansweredCreations() : super(latency: Duration.zero);

  @override
  Future<void> createBlock(int courtId, CourtBlockDraft draft) =>
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
  late CourtBlockRepositoryImpl repository;
  late List<void> announcements;

  const courtId = CourtBlockFakeDataSource.seededCourtId;
  const unknownBlockId = 999;
  final morning = DateTime(2026, 8, 3, 8);
  final noon = DateTime(2026, 8, 3, 12);

  void listenTo(CourtBlockFakeDataSource source) {
    repository = CourtBlockRepositoryImpl(
      remoteDataSource: source,
      logger: const SilentLogger(),
    );
    announcements = [];
    repository.blockChanges.listen(announcements.add);
  }

  setUp(() => listenTo(CourtBlockFakeDataSource(latency: Duration.zero)));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a created block and a removed block are announced', () async {
    await repository.createBlock(
      courtId,
      CourtBlockDraft(startsAt: morning, endsAt: noon),
    );
    await repository.removeBlock(
      courtId,
      CourtBlockFakeDataSource.seededBlockId,
    );
    await settle();

    expect(announcements, hasLength(2));
  });

  test('a timed out creation announces, it may have gone through', () async {
    listenTo(UnansweredCreations());

    final result = await repository.createBlock(
      courtId,
      CourtBlockDraft(startsAt: morning, endsAt: noon),
    );
    await settle();

    expect(result.getLeft().toNullable(), isA<ResponseTimeoutFailure>());
    expect(announcements, hasLength(1));
  });

  test('removing a block that is already gone announces, the list is stale',
      () async {
    final result = await repository.removeBlock(courtId, unknownBlockId);
    await settle();

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    expect(announcements, hasLength(1));
  });

  test('a rejected block announces nothing, the blocks did not change',
      () async {
    final result = await repository.createBlock(
      courtId,
      CourtBlockDraft(startsAt: noon, endsAt: morning),
    );
    await settle();

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    expect(announcements, isEmpty);
  });

  test('reading the blocks announces nothing', () async {
    await repository.loadBlocks(courtId, from: morning);
    await settle();

    expect(announcements, isEmpty);
  });
}
