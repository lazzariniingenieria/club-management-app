import 'package:club_management_app/shared/formatters/display_formats.dart';
import 'package:club_management_app/shared/formatters/peso_amount.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showing pesos', () {
    test('groups thousands and leaves whole pesos without decimals', () {
      expect(DisplayFormats.pesos(1500000), r'$15.000');
    });

    test('shows cents with a comma and two digits', () {
      expect(DisplayFormats.pesos(1500050), r'$15.000,50');
      expect(DisplayFormats.pesos(1500005), r'$15.000,05');
    });

    test('nothing is zero pesos, and less than a peso keeps its zero', () {
      expect(DisplayFormats.pesos(0), r'$0');
      expect(DisplayFormats.pesos(5), r'$0,05');
    });

    test('reads exactly as the amount field shows it', () {
      for (final cents in [0, 5, 1500000, 1500050, 1234567891]) {
        expect(DisplayFormats.pesos(cents), '\$${PesoAmount.textFor(cents)}');
      }
    });
  });

  test('groups the dni by thousands', () {
    expect(DisplayFormats.dni('30222333'), '30.222.333');
  });
}
