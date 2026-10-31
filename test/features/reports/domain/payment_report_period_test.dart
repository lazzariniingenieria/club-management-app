import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/reports/domain/entities/payment_report_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a single month spans from its first to its last day', () {
    const february = PaymentReportPeriod.single(BillingMonth(2028, 2));

    expect(february.firstDay, DateTime(2028, 2, 1));
    expect(february.lastDay, DateTime(2028, 2, 29));
  });

  test('a range ends on the last day of its last month', () {
    const period = PaymentReportPeriod(
      from: BillingMonth(2026, 11),
      to: BillingMonth(2026, 12),
    );

    expect(period.firstDay, DateTime(2026, 11, 1));
    expect(period.lastDay, DateTime(2026, 12, 31));
    expect(period.isValid, isTrue);
  });

  test('a range that ends before it starts is invalid', () {
    const period = PaymentReportPeriod(
      from: BillingMonth(2026, 10),
      to: BillingMonth(2026, 8),
    );

    expect(period.isValid, isFalse);
  });
}
