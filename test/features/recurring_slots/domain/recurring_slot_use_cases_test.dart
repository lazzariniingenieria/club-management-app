import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot_draft.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot_validity.dart';
import 'package:club_management_app/features/recurring_slots/domain/repositories/recurring_slot_repository.dart';
import 'package:club_management_app/features/recurring_slots/domain/usecases/create_recurring_slot_use_case.dart';
import 'package:club_management_app/features/recurring_slots/domain/usecases/deactivate_recurring_slot_use_case.dart';
import 'package:club_management_app/features/recurring_slots/domain/usecases/renew_recurring_slot_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringSlotRepository extends Mock
    implements RecurringSlotRepository {}

final validity = RecurringSlotValidity(
  from: DateTime(2026, 11, 17),
  until: DateTime(2027, 5, 17),
);

final draft = RecurringSlotDraft(
  courtId: 1,
  memberId: 10,
  weekday: DateTime.tuesday,
  startTime: const ClockTime(18, 0),
  endTime: const ClockTime(19, 0),
  validity: validity,
);

RecurringSlot slotFor(
  RecurringSlotValidity validity, {
  int id = 7,
  RecurringSlotState state = RecurringSlotState.current,
}) {
  return RecurringSlot(
    id: id,
    courtId: 1,
    memberId: 10,
    weekday: DateTime.tuesday,
    startTime: const ClockTime(18, 0),
    endTime: const ClockTime(19, 0),
    validFrom: validity.from,
    validUntil: validity.until,
    state: state,
  );
}

void main() {
  late MockRecurringSlotRepository repository;

  setUpAll(() {
    registerFallbackValue(draft);
    registerFallbackValue(validity);
  });

  setUp(() => repository = MockRecurringSlotRepository());

  group('create', () {
    test('rejects a draft with both a member and a description', () async {
      final both = RecurringSlotDraft(
        courtId: 1,
        memberId: 10,
        description: 'Clases',
        weekday: DateTime.tuesday,
        startTime: const ClockTime(18, 0),
        endTime: const ClockTime(19, 0),
        validity: validity,
      );

      final result = await CreateRecurringSlotUseCase(repository)(both);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => repository.createRecurringSlot(any()));
    });

    test('a timeout that went through counts as created', () async {
      when(() => repository.createRecurringSlot(any()))
          .thenAnswer((_) async => const Left(ResponseTimeoutFailure()));
      when(() => repository.loadRecurringSlots())
          .thenAnswer((_) async => Right([slotFor(validity)]));

      final result = await CreateRecurringSlotUseCase(repository)(draft);

      expect(result.getRight().toNullable()?.id, 7);
    });

    test('a timeout that did not go through stays a timeout', () async {
      when(() => repository.createRecurringSlot(any()))
          .thenAnswer((_) async => const Left(ResponseTimeoutFailure()));
      when(() => repository.loadRecurringSlots())
          .thenAnswer((_) async => const Right([]));

      final result = await CreateRecurringSlotUseCase(repository)(draft);

      expect(result.getLeft().toNullable(), isA<ResponseTimeoutFailure>());
    });
  });

  test('renewing with a timeout looks for the renewed slot', () async {
    final original = slotFor(
      RecurringSlotValidity(
        from: DateTime(2026, 5, 17),
        until: DateTime(2026, 11, 16),
      ),
      id: 3,
      state: RecurringSlotState.expired,
    );
    when(() => repository.renewRecurringSlot(3, validity))
        .thenAnswer((_) async => const Left(ResponseTimeoutFailure()));
    when(() => repository.loadRecurringSlots())
        .thenAnswer((_) async => Right([original, slotFor(validity)]));

    final result = await RenewRecurringSlotUseCase(repository)(
      original,
      validity,
    );

    expect(result.getRight().toNullable()?.id, 7);
  });

  test('deactivating a slot another admin already deactivated succeeds',
      () async {
    when(() => repository.deactivateRecurringSlot(7))
        .thenAnswer((_) async => const Left(ConflictFailure()));

    final result = await DeactivateRecurringSlotUseCase(repository)(7);

    expect(result.isRight(), isTrue);
  });
}
