import '../../core/constants/app_strings.dart';
import 'digit_layout_formatter.dart';
import 'peso_amount.dart';

abstract final class DisplayFormats {
  static String pesos(int cents) => '\$${PesoAmount.textFor(cents)}';

  static String dni(String digits) => DigitLayouts.groupedByThousands(digits);

  static String listed(List<String> labels) {
    if (labels.length <= 1) return labels.join();

    final head = labels.sublist(0, labels.length - 1).join(', ');

    return AppStrings.listed(head, labels.last);
  }
}
