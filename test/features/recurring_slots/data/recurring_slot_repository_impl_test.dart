import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/recurring_slots/data/datasources/recurring_slot_remote_data_source.dart';
import 'package:club_management_app/features/recurring_slots/data/repositories/recurring_slot_repository_impl.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot_clash.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot_draft.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot_validity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements RecurringSlotRemoteDataSource {}

class SilentLogger implements AppLogger {
  @override
  void info(String message, {String? context}) {}

  @override
  void warning(String message, {String? context}) {}

  @override
  void error(
    String message, {
    String? context,
    Object? cause,
    StackTrace? stackTrace,
  }) {}
}

void main() {
  final draft = RecurringSlotDraft(
    courtId: 1,
    memberId: 10,
    weekday: DateTime.tuesday,
    startTime: const ClockTime(18, 0),
    endTime: const ClockTime(19, 0),
    validity: RecurringSlotValidity(
      from: DateTime(2026, 11, 17),
      until: DateTime(2027, 5, 17),
    ),
  );
  late MockRemote remote;
  late RecurringSlotRepositoryImpl repository;

  setUp(() {
    remote = MockRemote();
    repository = RecurringSlotRepositoryImpl(
      remoteDataSource: remote,
      logger: SilentLogger(),
    );
  });

  test('a 409 with dates becomes the list of clashes', () async {
    when(() => remote.createRecurringSlot(draft)).thenThrow(
      ConflictException('conflicts', ['2026-12-01: court blocked']),
    );

    final result = await repository.createRecurringSlot(draft);

    expect(
      result.getLeft().toNullable(),
      RecurringSlotClashFailure([
        RecurringSlotClash(
          date: DateTime(2026, 12, 1),
          reason: ClashReason.blocked,
        ),
      ]),
    );
  });

  test('a 409 without dates stays a plain conflict', () async {
    when(() => remote.createRecurringSlot(draft))
        .thenThrow(ConflictException('constraint'));

    final result = await repository.createRecurringSlot(draft);
    final failure = result.getLeft().toNullable();

    expect(failure, isA<ConflictFailure>());
    expect(failure, isNot(isA<RecurringSlotClashFailure>()));
  });

  test('announces a change only when something may have changed', () async {
    final changes = <void>[];
    repository.recurringSlotChanges.listen(changes.add);
    when(() => remote.createRecurringSlot(draft)).thenThrow(
      ConflictException('conflicts', ['2026-12-01: court already reserved']),
    );
    when(() => remote.deactivateRecurringSlot(7)).thenAnswer((_) async {});

    await repository.createRecurringSlot(draft);
    await repository.deactivateRecurringSlot(7);
    await Future<void>.delayed(Duration.zero);

    expect(changes, hasLength(1));
  });
}
