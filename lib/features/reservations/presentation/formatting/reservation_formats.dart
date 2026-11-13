import '../../../../core/constants/app_strings.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../courts/domain/entities/clock_time.dart';
import '../../../courts/domain/entities/court_block.dart';
import '../../../courts/presentation/formatting/court_block_formats.dart';
import '../../../courts/presentation/formatting/court_formats.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/start_option.dart';

abstract final class ReservationFormats {
  static String hours(ClockTime start, ClockTime end) =>
      AppStrings.reservationHours(
        CourtFormats.time(start),
        CourtFormats.time(end),
      );

  static String ofReservation(Reservation reservation) =>
      hours(reservation.startTime, reservation.endTime);

  static String holder(Member? member) =>
      member?.fullName ?? AppStrings.reservationActivity;

  static String memberWithDni(Member member) {
    final dni = AppStrings.memberDni(DisplayFormats.dni(member.dni));

    return '${member.fullName} · $dni';
  }

  static String blockOfTheDay(CourtBlock block) => AppStrings.agendaBlocked(
        AppStrings.reservationHours(
          CourtBlockFormats.time(block.startsAt),
          CourtBlockFormats.time(block.endsAt),
        ),
        CourtBlockFormats.reason(block),
      );

  static String startOption(StartOption option) {
    final time = CourtFormats.time(option.start);

    return switch (option.unavailability) {
      null => time,
      SlotUnavailability.past =>
        AppStrings.slotUnavailable(time, AppStrings.slotPast),
      SlotUnavailability.reserved =>
        AppStrings.slotUnavailable(time, AppStrings.slotReserved),
      SlotUnavailability.blocked =>
        AppStrings.slotUnavailable(time, AppStrings.slotBlocked),
    };
  }
}
