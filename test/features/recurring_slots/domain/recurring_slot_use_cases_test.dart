import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot_clash.dart';
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

final clash = RecurringSlotClashFailure([
  RecurringSlotClash(
    date: DateTime(2026, 11, 17),
    reason: ClashReason.reserved,
  ),
]);

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

    test('a clash against the slot it had just created counts as created',
        () async {
      when(() => repository.createRecurringSlot(any()))
          .thenAnswer((_) async => Left(clash));
      when(() => repository.loadRecurringSlots())
          .thenAnswer((_) async => Right([slotFor(validity)]));

      final result = await CreateRecurringSlotUseCase(repository)(draft);

      expect(result.getRight().toNullable()?.id, 7);
    });

    test("a clash with someone else's reservation is still reported",
        () async {
      when(() => repository.createRecurringSlot(any()))
          .thenAnswer((_) async => Left(clash));
      when(() => repository.loadRecurringSlots())
          .thenAnswer((_) async => const Right([]));

      final result = await CreateRecurringSlotUseCase(repository)(draft);

      expect(result.getLeft().toNullable(), clash);
    });

    test('a creation without errors makes a single request', () async {
      when(() => repository.createRecurringSlot(any()))
          .thenAnswer((_) async => Right(slotFor(validity)));

      await CreateRecurringSlotUseCase(repository)(draft);

      verifyNever(() => repository.loadRecurringSlots());
    });
  });

  RecurringSlot expiredOriginal() => slotFor(
        RecurringSlotValidity(
          from: DateTime(2026, 5, 17),
          until: DateTime(2026, 11, 16),
        ),
        id: 3,
        state: RecurringSlotState.expired,
      );

  test('a renewal clashing with the slot it had just renewed counts as done',
      () async {
    final original = expiredOriginal();
    when(() => repository.renewRecurringSlot(3, validity))
        .thenAnswer((_) async => Left(clash));
    when(() => repository.loadRecurringSlots())
        .thenAnswer((_) async => Right([original, slotFor(validity)]));

    final result = await RenewRecurringSlotUseCase(repository)(
      original,
      validity,
    );

    expect(result.getRight().toNullable()?.id, 7);
  });

  test("a renewal clashing with someone else's reservation is reported",
      () async {
    final original = expiredOriginal();
    when(() => repository.renewRecurringSlot(3, validity))
        .thenAnswer((_) async => Left(clash));
    when(() => repository.loadRecurringSlots())
        .thenAnswer((_) async => Right([original]));

    final result = await RenewRecurringSlotUseCase(repository)(
      original,
      validity,
    );

    expect(result.getLeft().toNullable(), clash);
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
