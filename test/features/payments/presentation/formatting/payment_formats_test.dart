import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/presentation/formatting/payment_formats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('summarizing the chosen months', () {
    String summary(List<BillingMonth> months) =>
        PaymentFormats.monthsSummary(months);

    test('says so when nothing is chosen', () {
      expect(summary(const []), AppStrings.registerPaymentNoMonths);
    });

    test('names a single month with its year', () {
      expect(summary(const [BillingMonth(2026, 9)]), 'Septiembre de 2026');
    });

    test('lists up to three months of one year, naming the year once', () {
      expect(
        summary(const [
          BillingMonth(2026, 10),
          BillingMonth(2026, 11),
          BillingMonth(2026, 12),
        ]),
        'Octubre, noviembre y diciembre de 2026',
      );
    });

    test('gives each month its year when the list crosses into another', () {
      expect(
        summary(const [BillingMonth(2026, 12), BillingMonth(2027, 1)]),
        'Diciembre 2026 y enero 2027',
      );
    });

    test('lists in calendar order, whatever order they were chosen in', () {
      expect(
        summary(const [BillingMonth(2026, 11), BillingMonth(2026, 9)]),
        'Septiembre y noviembre de 2026',
      );
    });

    test('turns more than three consecutive months into a range', () {
      expect(
        summary(const [
          BillingMonth(2026, 3),
          BillingMonth(2026, 4),
          BillingMonth(2026, 5),
          BillingMonth(2026, 6),
        ]),
        '4 meses, de marzo a junio 2026',
      );
    });

    test('a range across the turn of the year names both years', () {
      expect(
        summary([
          for (var month = const BillingMonth(2026, 10);
              month.isBefore(const BillingMonth(2027, 4));
              month = month.next)
            month,
        ]),
        '6 meses, de octubre 2026 a marzo 2027',
      );
    });

    test('more than three months with gaps read as "entre", not a range', () {
      expect(
        summary(const [
          BillingMonth(2026, 1),
          BillingMonth(2026, 2),
          BillingMonth(2026, 7),
          BillingMonth(2026, 12),
        ]),
        '4 meses, entre enero y diciembre 2026',
      );
    });
  });

  group('showing pesos', () {
    test('groups thousands and leaves whole pesos without decimals', () {
      expect(PaymentFormats.pesos(1500000), r'$15.000');
    });

    test('shows cents with a comma and two digits', () {
      expect(PaymentFormats.pesos(1500050), r'$15.000,50');
      expect(PaymentFormats.pesos(1500005), r'$15.000,05');
    });
  });
}
