import '../../../../core/constants/app_strings.dart';
import '../../../courts/domain/entities/clock_time.dart';
import '../../../courts/presentation/formatting/court_block_formats.dart';
import '../../../members/domain/entities/member.dart';
import '../../../reservations/presentation/formatting/reservation_formats.dart';
import '../../domain/entities/recurring_slot.dart';
import '../../domain/entities/recurring_slot_clash.dart';
import '../../domain/entities/recurring_slot_validity.dart';

abstract final class RecurringSlotFormats {
  static const int expiryWarningDays = 30;

  static String weekday(int weekday) =>
      _capitalized(AppStrings.weekdayNames[weekday - DateTime.monday]);

  static String _plural(int weekday) =>
      AppStrings.weekdayPlurals[weekday - DateTime.monday];

  static String everyWeek(int weekday, ClockTime start, ClockTime end) =>
      AppStrings.recurringSlotEveryWeek(
        _plural(weekday),
        ReservationFormats.hours(start, end),
      );

  static String hoursOf(RecurringSlot slot) =>
      ReservationFormats.hours(slot.startTime, slot.endTime);

  static String ofSlot(RecurringSlot slot) =>
      everyWeek(slot.weekday, slot.startTime, slot.endTime);

  static String range(RecurringSlotValidity validity) =>
      AppStrings.recurringSlotRange(
        _date(validity.from),
        _date(validity.until),
      );

  static String rangeOfSlot(RecurringSlot slot) => range(
        RecurringSlotValidity(from: slot.validFrom, until: slot.validUntil),
      );

  static String until(DateTime value) =>
      AppStrings.recurringSlotUntil(_date(value));

  static String datesSummary(
    int weekday,
    List<DateTime> dates,
    RecurringSlotValidity validity,
  ) {
    final count = AppStrings.recurringSlotDateCount(
      dates.length,
      singular: AppStrings.weekdayNames[weekday - DateTime.monday],
      plural: _plural(weekday),
    );

    return AppStrings.recurringSlotDatesSummary(count, range(validity));
  }

  static String holder(RecurringSlot slot, Member? member) => slot.isActivity
      ? slot.description ?? AppStrings.reservationActivity
      : ReservationFormats.holder(member);

  static String state(RecurringSlotState state) => switch (state) {
        RecurringSlotState.current => AppStrings.recurringSlotStateCurrent,
        RecurringSlotState.expired => AppStrings.recurringSlotStateExpired,
        RecurringSlotState.inactive => AppStrings.recurringSlotStateInactive,
      };

  static String? expiryNotice(RecurringSlot slot, DateTime today) {
    if (slot.state == RecurringSlotState.expired) {
      return AppStrings.recurringSlotExpiredOn(_date(slot.validUntil));
    }
    final days = slot.daysUntilExpiry(today);
    final isClose =
        slot.state == RecurringSlotState.current && days <= expiryWarningDays;

    return isClose ? AppStrings.recurringSlotExpiresIn(days) : null;
  }

  static String clash(RecurringSlotClash clash) => AppStrings.clashLine(
        CourtBlockFormats.day(clash.date),
        switch (clash.reason) {
          ClashReason.reserved => AppStrings.clashReserved,
          ClashReason.blocked => AppStrings.clashBlocked,
          ClashReason.unknown => AppStrings.clashTaken,
        },
      );

  static String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }

  static String _capitalized(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
}
