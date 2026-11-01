import '../../../../core/constants/app_strings.dart';
import '../../../payments/domain/entities/billing_month.dart';
import '../../domain/entities/payment_report_period.dart';

abstract final class FeeReceiptsRequest {
  static const String _paidFromKey = 'paidFrom';
  static const String _paidToKey = 'paidTo';

  static Map<String, dynamic> queryOf(PaymentReportPeriod period) => {
        _paidFromKey: isoDay(period.firstDay),
        _paidToKey: isoDay(period.lastDay),
      };

  static String fileNameFor(PaymentReportPeriod period) =>
      'cuotas-cobradas-${_periodSlug(period)}.pdf';

  static String _periodSlug(PaymentReportPeriod period) {
    final to = '${_monthName(period.to)}-${period.to.year}';
    if (period.isSingleMonth) return to;

    final from = period.from.year == period.to.year
        ? _monthName(period.from)
        : '${_monthName(period.from)}-${period.from.year}';

    return '$from-a-$to';
  }

  static String _monthName(BillingMonth month) =>
      AppStrings.monthNames[month.month - 1];

  static String isoDay(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');

    return '${day.year}-$month-$dayOfMonth';
  }
}
