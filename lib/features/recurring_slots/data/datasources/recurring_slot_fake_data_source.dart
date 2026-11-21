import '../../../../core/errors/exceptions.dart';
import '../../../courts/data/models/court_block_model.dart';
import '../../../courts/domain/entities/clock_time.dart';
import '../../../reservations/data/datasources/reservation_fake_data_source.dart';
import '../../../reservations/data/models/reservation_model.dart';
import '../../../reservations/domain/entities/reservation.dart';
import '../../domain/entities/recurring_slot.dart';
import '../../domain/entities/recurring_slot_draft.dart';
import '../../domain/entities/recurring_slot_validity.dart';
import '../models/recurring_slot_model.dart';
import 'recurring_slot_remote_data_source.dart';

class RecurringSlotFakeDataSource implements RecurringSlotRemoteDataSource {
  RecurringSlotFakeDataSource({
    this.latency = const Duration(milliseconds: 600),
    DateTime Function() clock = DateTime.now,
    this.reservations,
  })  : _clock = clock,
        _slots = _seeded(clock());

  final Duration latency;
  final DateTime Function() _clock;
  final ReservationFakeDataSource? reservations;
  final List<RecurringSlotModel> _slots;

  static const int seededMemberSlotId = 1;
  static const int seededActivitySlotId = 2;
  static const int seededExpiredSlotId = 3;
  static const int seededExpiredMemberId = 3;

  static List<RecurringSlotModel> _seeded(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final inTwoDays = DateTime(now.year, now.month, now.day + 2);
    final validity =
        RecurringSlotValidity.preset(today, ValidityPreset.sixMonths);

    return [
      RecurringSlotModel(
        id: seededMemberSlotId,
        courtId: 1,
        memberId: ReservationFakeDataSource.seededRecurringMemberId,
        weekday: inTwoDays.weekday,
        startTime: const ClockTime(18, 0),
        endTime: const ClockTime(19, 0),
        validFrom: validity.from,
        validUntil: validity.until,
        state: RecurringSlotState.current,
      ),
      RecurringSlotModel(
        id: seededActivitySlotId,
        courtId: ReservationFakeDataSource.seededCourtId,
        description: ReservationFakeDataSource.seededActivity,
        weekday: inTwoDays.weekday,
        startTime: const ClockTime(17, 0),
        endTime: const ClockTime(18, 0),
        validFrom: validity.from,
        validUntil: validity.until,
        state: RecurringSlotState.current,
      ),
      RecurringSlotModel(
        id: seededExpiredSlotId,
        courtId: 1,
        memberId: seededExpiredMemberId,
        weekday: DateTime.saturday,
        startTime: const ClockTime(10, 0),
        endTime: const ClockTime(11, 0),
        validFrom: DateTime(today.year, today.month - 6, today.day),
        validUntil: DateTime(today.year, today.month, today.day - 3),
        state: RecurringSlotState.expired,
      ),
    ];
  }

  @override
  Future<List<RecurringSlotModel>> fetchRecurringSlots() async {
    await Future<void>.delayed(latency);

    return [..._slots]..sort(_byWeekdayAndStart);
  }

  @override
  Future<RecurringSlotModel> createRecurringSlot(
    RecurringSlotDraft draft,
  ) async {
    await Future<void>.delayed(latency);
    final dates = draft.dates(_clock());
    if (dates.isEmpty) throw ValidationException('No future dates');
    _rejectClashes(draft, dates);

    final slot = _fromDraft(_nextId(), draft);
    _slots.add(slot);
    reservations?.addOccurrences(_occurrenceOf(slot), dates);

    return slot;
  }

  @override
  Future<RecurringSlotModel> renewRecurringSlot(
    int recurringSlotId,
    RecurringSlotValidity validity,
  ) {
    final original = _find(recurringSlotId);

    return createRecurringSlot(
      RecurringSlotDraft(
        courtId: original.courtId,
        memberId: original.memberId,
        description: original.description,
        weekday: original.weekday,
        startTime: original.startTime,
        endTime: original.endTime,
        validity: validity,
      ),
    );
  }

  @override
  Future<void> deactivateRecurringSlot(int recurringSlotId) async {
    await Future<void>.delayed(latency);
    final slot = _find(recurringSlotId);
    if (!slot.isActive) throw ConflictException('Already inactive');

    _slots[_slots.indexOf(slot)] =
        _withState(slot, RecurringSlotState.inactive);
    reservations?.cancelUpcomingOfRecurringSlot(recurringSlotId);
  }

  void _rejectClashes(RecurringSlotDraft draft, List<DateTime> dates) {
    final taken = reservations?.takenDates(
          courtId: draft.courtId,
          dates: dates,
          start: draft.startTime,
          end: draft.endTime,
        ) ??
        const <DateTime>[];
    if (taken.isEmpty) return;

    throw ConflictException('recurring slot conflicts', [
      for (final date in taken)
        '${CourtBlockModel.dayToJson(date)}: court already reserved',
    ]);
  }

  RecurringSlotModel _find(int recurringSlotId) {
    for (final slot in _slots) {
      if (slot.id == recurringSlotId) return slot;
    }
    throw NotFoundException('Unknown recurring slot $recurringSlotId');
  }

  static ReservationModel _occurrenceOf(RecurringSlotModel slot) {
    return ReservationModel(
      id: 0,
      courtId: slot.courtId,
      memberId: slot.memberId,
      source: slot.isActivity
          ? ReservationSource.activity
          : ReservationSource.recurring,
      recurringSlotId: slot.id,
      description: slot.description,
      date: slot.validFrom,
      startTime: slot.startTime,
      endTime: slot.endTime,
    );
  }

  static RecurringSlotModel _fromDraft(int id, RecurringSlotDraft draft) {
    final description = draft.description?.trim();

    return RecurringSlotModel(
      id: id,
      courtId: draft.courtId,
      memberId: draft.memberId,
      description:
          description == null || description.isEmpty ? null : description,
      weekday: draft.weekday,
      startTime: draft.startTime,
      endTime: draft.endTime,
      validFrom: draft.validity.from,
      validUntil: draft.validity.until,
      state: RecurringSlotState.current,
    );
  }

  static RecurringSlotModel _withState(
    RecurringSlotModel slot,
    RecurringSlotState state,
  ) {
    return RecurringSlotModel(
      id: slot.id,
      courtId: slot.courtId,
      memberId: slot.memberId,
      description: slot.description,
      weekday: slot.weekday,
      startTime: slot.startTime,
      endTime: slot.endTime,
      validFrom: slot.validFrom,
      validUntil: slot.validUntil,
      state: state,
    );
  }

  static int _byWeekdayAndStart(RecurringSlot a, RecurringSlot b) {
    final byWeekday = a.weekday.compareTo(b.weekday);

    return byWeekday != 0 ? byWeekday : a.startTime.compareTo(b.startTime);
  }

  int _nextId() {
    var highestId = 0;

    for (final slot in _slots) {
      if (slot.id > highestId) highestId = slot.id;
    }

    return highestId + 1;
  }
}
