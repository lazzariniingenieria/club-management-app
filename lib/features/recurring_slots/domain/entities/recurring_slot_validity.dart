import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/clock_time.dart';

enum ValidityPreset {
  threeMonths(3),
  sixMonths(6),
  oneYear(12);

  final int months;

  const ValidityPreset(this.months);

  static const ValidityPreset suggested = sixMonths;
}

class RecurringSlotValidity extends Equatable {
  final DateTime from;
  final DateTime until;

  const RecurringSlotValidity({required this.from, required this.until});

  factory RecurringSlotValidity.preset(DateTime from, ValidityPreset preset) =>
      RecurringSlotValidity(
          from: from, until: _monthsAfter(from, preset.months));

  static DateTime latestUntil(DateTime from) => _monthsAfter(from, 12);

  static DateTime renewalStart(DateTime validUntil, DateTime today) {
    final nextDay =
        DateTime(validUntil.year, validUntil.month, validUntil.day + 1);

    return nextDay.isBefore(today) ? today : nextDay;
  }

  bool get isWithinLimits =>
      until.isAfter(from) && !until.isAfter(latestUntil(from));

  ValidityPreset? get preset {
    for (final preset in ValidityPreset.values) {
      if (until == _monthsAfter(from, preset.months)) return preset;
    }

    return null;
  }

  List<DateTime> datesOn(
    int weekday, {
    required ClockTime start,
    required DateTime now,
  }) {
    final daysToFirst = (weekday - from.weekday) % DateTime.daysPerWeek;
    final today = DateTime(now.year, now.month, now.day);
    final dates = <DateTime>[];

    for (var offset = daysToFirst;; offset += DateTime.daysPerWeek) {
      final date = DateTime(from.year, from.month, from.day + offset);
      if (date.isAfter(until)) return dates;
      if (!_hasStarted(date, start, today, now)) dates.add(date);
    }
  }

  static bool _hasStarted(
    DateTime date,
    ClockTime start,
    DateTime today,
    DateTime now,
  ) {
    if (date != today) return date.isBefore(today);

    return !DateTime(date.year, date.month, date.day, start.hour, start.minute)
        .isAfter(now);
  }

  static DateTime _monthsAfter(DateTime from, int months) {
    final target = DateTime(from.year, from.month + months);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    final day = from.day > lastDay ? lastDay : from.day;

    return DateTime(target.year, target.month, day);
  }

  @override
  List<Object?> get props => [from, until];
}
