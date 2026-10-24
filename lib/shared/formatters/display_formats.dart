import 'digit_layout_formatter.dart';
import 'peso_amount.dart';

abstract final class DisplayFormats {
  static String pesos(int cents) => '\$${PesoAmount.textFor(cents)}';

  static String dni(String digits) => DigitLayouts.groupedByThousands(digits);
}
