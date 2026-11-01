import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/reports/data/models/fee_receipts_request.dart';
import 'package:club_management_app/features/reports/domain/entities/payment_report_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the PDF file name', () {
    test('a single month reads as the month and its year', () {
      const period = PaymentReportPeriod.single(BillingMonth(2026, 10));

      expect(
        FeeReceiptsRequest.fileNameFor(period),
        'cuotas-cobradas-octubre-2026.pdf',
      );
    });

    test('a range within a year names the year once', () {
      const period = PaymentReportPeriod(
        from: BillingMonth(2026, 8),
        to: BillingMonth(2026, 10),
      );

      expect(
        FeeReceiptsRequest.fileNameFor(period),
        'cuotas-cobradas-agosto-a-octubre-2026.pdf',
      );
    });

    test('a range across years names both', () {
      const period = PaymentReportPeriod(
        from: BillingMonth(2025, 11),
        to: BillingMonth(2026, 2),
      );

      expect(
        FeeReceiptsRequest.fileNameFor(period),
        'cuotas-cobradas-noviembre-2025-a-febrero-2026.pdf',
      );
    });
  });

  test('still asks the backend by ISO day, which is what it parses', () {
    const period = PaymentReportPeriod.single(BillingMonth(2026, 2));

    expect(FeeReceiptsRequest.queryOf(period), {
      'paidFrom': '2026-02-01',
      'paidTo': '2026-02-28',
    });
  });
}
