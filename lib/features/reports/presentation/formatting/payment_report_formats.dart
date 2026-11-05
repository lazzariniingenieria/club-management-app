import '../../../../core/constants/app_strings.dart';
import '../../../payments/presentation/formatting/payment_formats.dart';
import '../../domain/entities/payment_report_period.dart';

abstract final class PaymentReportFormats {
  static String periodLabel(PaymentReportPeriod period) {
    if (period.isSingleMonth) return PaymentFormats.monthTitle(period.from);

    final to = PaymentFormats.monthWithYear(period.to);
    if (period.from.year != period.to.year) {
      return AppStrings.reportPeriodRange(
        PaymentFormats.monthTitle(period.from),
        to,
      );
    }

    return AppStrings.monthsInYear(
      AppStrings.reportPeriodRange(
        PaymentFormats.capitalized(PaymentFormats.monthName(period.from)),
        PaymentFormats.monthName(period.to),
      ),
      period.to.year,
    );
  }
}
