import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot.dart';
import 'package:club_management_app/features/recurring_slots/presentation/formatting/recurring_slot_formats.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringSlot slotUntil(DateTime validUntil) => RecurringSlot(
      id: 7,
      courtId: 1,
      memberId: 10,
      weekday: DateTime.tuesday,
      startTime: const ClockTime(18, 0),
      endTime: const ClockTime(19, 0),
      validFrom: DateTime(2026, 9, 29),
      validUntil: validUntil,
      state: RecurringSlotState.current,
    );

void main() {
  final slot = slotUntil(DateTime(2027, 3, 30));

  test('the row title shows the hours and the court', () {
    expect(
      RecurringSlotFormats.rowTitle(slot, 'Cancha de Pádel 1'),
      '18:00 a 19:00 · Cancha de Pádel 1',
    );
  });

  test('the row subtitle shows who holds it and until when', () {
    expect(
      RecurringSlotFormats.rowSubtitle('Marcos Gómez', slot),
      'Marcos Gómez · hasta el 30/03/2027',
    );
  });

  test('a current slot past its end on a fast clock reads as expired', () {
    final notice = RecurringSlotFormats.expiryNotice(
      slotUntil(DateTime(2026, 11, 15)),
      DateTime(2026, 11, 16),
    );

    expect(notice, AppStrings.recurringSlotExpiredOn('15/11/2026'));
  });

  test('a current slot close to its end says in how many days', () {
    final notice = RecurringSlotFormats.expiryNotice(
      slotUntil(DateTime(2026, 11, 17)),
      DateTime(2026, 11, 16),
    );

    expect(notice, AppStrings.recurringSlotExpiresIn(1));
  });
}
