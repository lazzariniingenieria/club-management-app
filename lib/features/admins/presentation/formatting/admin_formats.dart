import '../../../../core/constants/app_strings.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/admin.dart';

abstract final class AdminFormats {
  static String displayName(Admin admin, Member? linkedMember) =>
      linkedMember?.fullName ??
      AppStrings.memberDni(DisplayFormats.dni(admin.dni));
}
