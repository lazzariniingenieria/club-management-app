import '../../../../core/constants/app_strings.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../domain/entities/member.dart';

abstract final class MemberFormats {
  static String dni(Member member) {
    final dni = member.dni;
    if (dni == null) return AppStrings.memberWithoutDni;

    return AppStrings.memberDni(DisplayFormats.dni(dni));
  }
}
