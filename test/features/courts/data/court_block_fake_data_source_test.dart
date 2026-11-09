import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/courts/data/datasources/court_block_fake_data_source.dart';
import 'package:club_management_app/features/courts/domain/entities/court_block_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 9, 10, 30);
  final today = DateTime(2026, 11, 9);
  late CourtBlockFakeDataSource source;

  setUp(() {
    source = CourtBlockFakeDataSource(latency: Duration.zero, clock: () => now);
  });

  test('lists only the blocks of the court that end after the day starts',
      () async {
    await source.createBlock(
      1,
      CourtBlockDraft(
        startsAt: DateTime(2026, 11, 1, 8),
        endsAt: DateTime(2026, 11, 2, 8),
      ),
    );
    await source.createBlock(
      2,
      CourtBlockDraft(
        startsAt: DateTime(2026, 11, 10, 8),
        endsAt: DateTime(2026, 11, 10, 9),
      ),
    );

    final blocks = await source.fetchBlocks(1, from: today);

    expect(blocks.map((block) => block.id), [
      CourtBlockFakeDataSource.seededBlockId,
    ]);
  });

  test('lists the blocks earliest first', () async {
    await source.createBlock(
      1,
      CourtBlockDraft(
        startsAt: DateTime(2026, 11, 9, 18),
        endsAt: DateTime(2026, 11, 9, 20),
      ),
    );

    final blocks = await source.fetchBlocks(1, from: today);

    expect(blocks.first.startsAt, DateTime(2026, 11, 9, 18));
  });

  test('a block that does not end after it starts is rejected, like the API',
      () {
    expect(
      () => source.createBlock(
        1,
        CourtBlockDraft(
          startsAt: DateTime(2026, 11, 9, 10),
          endsAt: DateTime(2026, 11, 9, 10),
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('removing a block of another court is not found', () {
    expect(
      () => source.removeBlock(2, CourtBlockFakeDataSource.seededBlockId),
      throwsA(isA<NotFoundException>()),
    );
  });
}
