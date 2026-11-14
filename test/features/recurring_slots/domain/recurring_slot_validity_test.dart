import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/recurring_slots/domain/entities/recurring_slot_validity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('presets', () {
    test('add whole months from the start', () {
      final validity = RecurringSlotValidity.preset(
        DateTime(2026, 11, 13),
        ValidityPreset.sixMonths,
      );

      expect(validity.until, DateTime(2027, 5, 13));
      expect(validity.preset, ValidityPreset.sixMonths);
    });

    test('fall on the last day when the month is shorter, like the API', () {
      final validity = RecurringSlotValidity.preset(
        DateTime(2026, 11, 30),
        ValidityPreset.threeMonths,
      );

      expect(validity.until, DateTime(2027, 2, 28));
    });

    test('one year is the longest validity allowed', () {
      final from = DateTime(2026, 11, 13);
      final oneYear =
          RecurringSlotValidity.preset(from, ValidityPreset.oneYear);
      final tooLong =
          RecurringSlotValidity(from: from, until: DateTime(2027, 11, 14));

      expect(oneYear.isWithinLimits, isTrue);
      expect(tooLong.isWithinLimits, isFalse);
      expect(tooLong.preset, isNull);
    });
  });

  group('renewal start', () {
    test('is the day after the current validity ends', () {
      expect(
        RecurringSlotValidity.renewalStart(
          DateTime(2026, 11, 30),
          DateTime(2026, 11, 13),
        ),
        DateTime(2026, 12, 1),
      );
    });

    test('is today when the slot already expired', () {
      expect(
        RecurringSlotValidity.renewalStart(
          DateTime(2026, 11, 10),
          DateTime(2026, 11, 13),
        ),
        DateTime(2026, 11, 13),
      );
    });
  });

  group('dates', () {
    final validity = RecurringSlotValidity(
      from: DateTime(2026, 11, 13),
      until: DateTime(2026, 12, 8),
    );

    test('start on the first matching weekday and include the last day', () {
      final dates = validity.datesOn(
        DateTime.tuesday,
        start: const ClockTime(18, 0),
        now: DateTime(2026, 11, 13, 9),
      );

      expect(dates, [
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 24),
        DateTime(2026, 12, 1),
        DateTime(2026, 12, 8),
      ]);
    });

    test('skip today when its time already started', () {
      final dates = validity.datesOn(
        DateTime.friday,
        start: const ClockTime(18, 0),
        now: DateTime(2026, 11, 13, 18, 30),
      );

      expect(dates.first, DateTime(2026, 11, 20));
    });

    test('keep today when its time is still ahead', () {
      final dates = validity.datesOn(
        DateTime.friday,
        start: const ClockTime(18, 0),
        now: DateTime(2026, 11, 13, 17),
      );

      expect(dates.first, DateTime(2026, 11, 13));
    });
  });
}
