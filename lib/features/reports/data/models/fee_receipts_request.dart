import '../../domain/entities/payment_report_period.dart';

abstract final class FeeReceiptsRequest {
  static const String _paidFromKey = 'paidFrom';
  static const String _paidToKey = 'paidTo';
  static final RegExp _fileNamePattern =
      RegExp(r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''');

  static Map<String, dynamic> queryOf(PaymentReportPeriod period) => {
        _paidFromKey: isoDay(period.firstDay),
        _paidToKey: isoDay(period.lastDay),
      };

  static String defaultFileName(PaymentReportPeriod period) =>
      'cuotas-cobradas-${isoDay(period.firstDay)}-al-${isoDay(period.lastDay)}.pdf';

  static String? fileNameFrom(String? contentDisposition) {
    if (contentDisposition == null) return null;

    return _fileNamePattern.firstMatch(contentDisposition)?.group(1);
  }

  static String isoDay(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');

    return '${day.year}-$month-$dayOfMonth';
  }
}
