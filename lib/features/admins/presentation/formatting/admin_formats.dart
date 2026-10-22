import '../../../../core/constants/app_strings.dart';
import '../../../members/domain/entities/member.dart';
import '../../../payments/presentation/formatting/payment_formats.dart';
import '../../domain/entities/admin.dart';

abstract final class AdminFormats {
  static String displayName(Admin admin, Member? linkedMember) =>
      linkedMember?.fullName ??
      AppStrings.memberDni(PaymentFormats.dni(admin.dni));
}
