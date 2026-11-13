import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/clock_time.dart';
import '../../domain/entities/court.dart';

abstract final class CourtFormats {
  static String time(ClockTime time) =>
      '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';

  static String hours(Court court) => AppStrings.courtHours(
        time(court.openingTime),
        time(court.closingTime),
      );

  static String details(Court court) {
    final type = court.type;

    return type == null
        ? hours(court)
        : AppStrings.courtDetails(type, hours(court));
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
