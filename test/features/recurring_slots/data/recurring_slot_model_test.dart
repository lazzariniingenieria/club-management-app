import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/recurring_slots/data/models/recurring_slot_model.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot_clash.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot_draft.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot_validity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a recurring slot as the API sends it', () {
    final slot = RecurringSlotModel.fromJson(const {
      'id': 4,
      'courtId': 3,
      'memberId': 10,
      'description': null,
      'dayOfWeek': 'TUESDAY',
      'startTime': '18:00:00',
      'endTime': '19:00:00',
      'validFrom': '2026-11-17',
      'validUntil': '2027-03-30',
      'active': true,
      'state': 'CURRENT',
      'createdAt': '2026-11-13T12:00:00Z',
      'createdByUserId': 2,
      'deactivatedAt': null,
      'deactivatedByUserId': null,
    });

    expect(slot.weekday, DateTime.tuesday);
    expect(slot.startTime, const ClockTime(18, 0));
    expect(slot.validUntil, DateTime(2027, 3, 30));
    expect(slot.state, RecurringSlotState.current);
    expect(slot.isActivity, isFalse);
  });

  test('an activity has a description and no member', () {
    final slot = RecurringSlotModel.fromJson(const {
      'id': 5,
      'courtId': 3,
      'memberId': null,
      'description': 'Clases de tenis',
      'dayOfWeek': 'SUNDAY',
      'startTime': '17:00:00',
      'endTime': '18:00:00',
      'validFrom': '2026-11-15',
      'validUntil': '2026-12-27',
      'state': 'EXPIRED',
    });

    expect(slot.weekday, DateTime.sunday);
    expect(slot.isActivity, isTrue);
    expect(slot.state, RecurringSlotState.expired);
  });

  test('sends the day of the week by name and a trimmed description', () {
    final body = RecurringSlotModel.bodyFromDraft(
      RecurringSlotDraft(
        courtId: 3,
        description: '  Clases de tenis ',
        weekday: DateTime.monday,
        startTime: const ClockTime(17, 0),
        endTime: const ClockTime(18, 0),
        validity: RecurringSlotValidity(
          from: DateTime(2026, 11, 16),
          until: DateTime(2027, 5, 16),
        ),
      ),
    );

    expect(body, {
      'courtId': 3,
      'memberId': null,
      'description': 'Clases de tenis',
      'dayOfWeek': 'MONDAY',
      'startTime': '17:00',
      'endTime': '18:00',
      'validFrom': '2026-11-16',
      'validUntil': '2027-05-16',
    });
  });

  test('reads the dates that clash from the details of the 409', () {
    final clashes = RecurringSlotModel.clashesFromDetails(const [
      '2026-12-01: court already reserved',
      '2026-12-08: court blocked',
      'not a date',
    ]);

    expect(clashes, [
      RecurringSlotClash(
        date: DateTime(2026, 12, 1),
        reason: ClashReason.reserved,
      ),
      RecurringSlotClash(
        date: DateTime(2026, 12, 8),
        reason: ClashReason.blocked,
      ),
    ]);
  });
}
