import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/courts/domain/entities/court_block.dart';
import 'package:club_management_app/features/courts/domain/entities/court_block_draft.dart';
import 'package:club_management_app/features/courts/domain/repositories/court_block_repository.dart';
import 'package:club_management_app/features/courts/domain/usecases/create_court_block_use_case.dart';
import 'package:club_management_app/features/courts/domain/usecases/load_court_blocks_use_case.dart';
import 'package:club_management_app/features/courts/domain/usecases/remove_court_block_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCourtBlockRepository extends Mock implements CourtBlockRepository {}

void main() {
  late MockCourtBlockRepository repository;
  final morning = DateTime(2026, 8, 3, 8);
  final noon = DateTime(2026, 8, 3, 12);

  setUpAll(() {
    registerFallbackValue(CourtBlockDraft(startsAt: morning, endsAt: noon));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() => repository = MockCourtBlockRepository());

  group('load', () {
    test('asks for the blocks from the start of today', () async {
      when(() => repository.loadBlocks(3, from: any(named: 'from')))
          .thenAnswer((_) async => const Right([]));

      await LoadCourtBlocksUseCase(
        repository,
        clock: () => DateTime(2026, 11, 9, 17, 45),
      )(3);

      verify(() => repository.loadBlocks(3, from: DateTime(2026, 11, 9)))
          .called(1);
    });
  });

  group('create without an answer in time', () {
    final draft = CourtBlockDraft(
      startsAt: morning,
      endsAt: noon,
      reason: 'Torneo',
    );

    CourtBlock listed({String? reason = 'Torneo'}) => CourtBlock(
          id: 9,
          courtId: 3,
          startsAt: morning,
          endsAt: noon,
          reason: reason,
        );

    void blocksAre(Either<Failure, List<CourtBlock>> blocks) {
      when(() => repository.createBlock(3, draft))
          .thenAnswer((_) async => const Left(ResponseTimeoutFailure()));
      when(() => repository.loadBlocks(3, from: DateTime(2026, 8, 3)))
          .thenAnswer((_) async => blocks);
    }

    test('a timeout whose block went through counts as created', () async {
      blocksAre(Right([listed()]));

      final result = await CreateCourtBlockUseCase(repository)(3, draft);

      expect(result.isRight(), isTrue);
      verify(() => repository.createBlock(3, draft)).called(1);
    });

    test('a timeout whose block did not go through is reported', () async {
      blocksAre(const Right([]));

      final result = await CreateCourtBlockUseCase(repository)(3, draft);

      expect(result.getLeft().toNullable(), const ResponseTimeoutFailure());
    });

    test('a block of the same hours with another reason is not the one sent',
        () async {
      blocksAre(Right([listed(reason: null)]));

      final result = await CreateCourtBlockUseCase(repository)(3, draft);

      expect(result.getLeft().toNullable(), const ResponseTimeoutFailure());
    });

    test('a timeout that could not be checked is reported', () async {
      blocksAre(const Left(NetworkFailure()));

      final result = await CreateCourtBlockUseCase(repository)(3, draft);

      expect(result.getLeft().toNullable(), const ResponseTimeoutFailure());
    });
  });

  group('create', () {
    test('trims the reason before sending', () async {
      final trimmed = CourtBlockDraft(
        startsAt: morning,
        endsAt: noon,
        reason: 'Torneo',
      );
      when(() => repository.createBlock(3, trimmed))
          .thenAnswer((_) async => const Right(null));

      final result = await CreateCourtBlockUseCase(repository)(
        3,
        CourtBlockDraft(startsAt: morning, endsAt: noon, reason: '  Torneo '),
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.createBlock(3, trimmed)).called(1);
    });

    test('a block that ends before it starts is never sent', () async {
      final result = await CreateCourtBlockUseCase(repository)(
        3,
        CourtBlockDraft(startsAt: noon, endsAt: morning),
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => repository.createBlock(any(), any()));
    });

    test('a reason longer than 150 characters is never sent', () async {
      final result = await CreateCourtBlockUseCase(repository)(
        3,
        CourtBlockDraft(startsAt: morning, endsAt: noon, reason: 'a' * 151),
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => repository.createBlock(any(), any()));
    });
  });

  group('remove', () {
    test('a block someone else already removed counts as removed', () async {
      when(() => repository.removeBlock(3, 8))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await RemoveCourtBlockUseCase(repository)(3, 8);

      expect(result.isRight(), isTrue);
    });

    test('any other failure is reported', () async {
      when(() => repository.removeBlock(3, 8))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await RemoveCourtBlockUseCase(repository)(3, 8);

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });
  });
}
