import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/clock_time.dart';
import '../../domain/entities/court_block.dart';
import 'court_formats.dart';

abstract final class CourtBlockFormats {
  static String day(DateTime value) {
    final weekday = AppStrings.weekdayAbbreviations[value.weekday - 1];
    final dayOfMonth = _twoDigits(value.day);
    final month = _twoDigits(value.month);

    return '$weekday $dayOfMonth/$month/${value.year}';
  }

  static String time(DateTime value) =>
      CourtFormats.time(ClockTime(value.hour, value.minute));

  static List<String> range(CourtBlock block) {
    if (block.isWithinOneDay) {
      return [
        AppStrings.courtBlockSameDay(
          _capitalized(day(block.startsAt)),
          time(block.startsAt),
          time(block.endsAt),
        ),
      ];
    }

    return [
      AppStrings.courtBlockFrom(day(block.startsAt), time(block.startsAt)),
      AppStrings.courtBlockUntil(day(block.endsAt), time(block.endsAt)),
    ];
  }

  static String reason(CourtBlock block) =>
      block.reason ?? AppStrings.courtBlockNoReason;

  static String _capitalized(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
