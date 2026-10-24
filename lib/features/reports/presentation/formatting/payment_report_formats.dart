import '../../../../core/constants/app_strings.dart';
import '../../../payments/presentation/formatting/payment_formats.dart';
import '../../domain/entities/payment_report_period.dart';

abstract final class PaymentReportFormats {
  static String periodLabel(PaymentReportPeriod period) {
    if (period.isSingleMonth) return PaymentFormats.monthTitle(period.from);

    return AppStrings.reportPeriodRange(
      PaymentFormats.monthTitle(period.from),
      PaymentFormats.monthWithYear(period.to),
    );
  }
}
