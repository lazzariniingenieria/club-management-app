import '../../../../core/constants/app_strings.dart';
import '../../../../shared/formatters/digit_layout_formatter.dart';
import '../../domain/entities/billing_month.dart';
import '../../domain/entities/payment_method.dart';
import 'peso_amount.dart';

abstract final class PaymentFormats {
  static const int _longListThreshold = 3;

  static String pesos(int cents) => '\$${PesoAmount.textFor(cents)}';

  static String dni(String digits) => DigitLayouts.groupedByThousands(digits);

  static String day(DateTime instant) {
    final local = instant.toLocal();
    final dayOfMonth = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$dayOfMonth/$month/${local.year}';
  }

  static String monthName(BillingMonth month) =>
      AppStrings.monthNames[month.month - 1];

  static String monthAbbreviation(int month) =>
      AppStrings.monthAbbreviations[month - 1];

  static String monthWithYear(BillingMonth month) =>
      '${monthName(month)} ${month.year}';

  static String monthTitle(BillingMonth month) =>
      capitalized(monthWithYear(month));

  static String method(PaymentMethod method) => switch (method) {
        PaymentMethod.cash => AppStrings.paymentMethodCash,
        PaymentMethod.transfer => AppStrings.paymentMethodTransfer,
        PaymentMethod.other => AppStrings.paymentMethodOther,
      };

  static String monthsSummary(Iterable<BillingMonth> months) {
    final sorted = BillingMonth.sorted(months);
    if (sorted.isEmpty) return AppStrings.registerPaymentNoMonths;

    final summary =
        sorted.length > _longListThreshold ? _range(sorted) : _listed(sorted);

    return capitalized(summary);
  }

  static String capitalized(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  static String _listed(List<BillingMonth> months) {
    final sameYear = _shareYear(months);
    final labels = [
      for (final month in months)
        sameYear ? monthName(month) : monthWithYear(month),
    ];
    final joined = labels.length == 1
        ? labels.single
        : AppStrings.monthsListed(
            labels.sublist(0, labels.length - 1).join(', '),
            labels.last,
          );

    return sameYear
        ? AppStrings.monthsInYear(joined, months.first.year)
        : joined;
  }

  static String _range(List<BillingMonth> months) {
    final from = _shareYear(months)
        ? monthName(months.first)
        : monthWithYear(months.first);
    final to = monthWithYear(months.last);

    return _areConsecutive(months)
        ? AppStrings.monthsRange(months.length, from, to)
        : AppStrings.monthsSpread(months.length, from, to);
  }

  static bool _shareYear(List<BillingMonth> months) =>
      months.every((month) => month.year == months.first.year);

  static bool _areConsecutive(List<BillingMonth> months) {
    for (var index = 1; index < months.length; index++) {
      if (!months[index - 1].isRightBefore(months[index])) return false;
    }

    return true;
  }
}
