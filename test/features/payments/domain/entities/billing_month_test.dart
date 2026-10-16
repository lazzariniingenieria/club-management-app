import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the first day of the month the API sends', () {
    expect(BillingMonth.parse('2026-07-01'), const BillingMonth(2026, 7));
  });

  test('writes the month back as its first day', () {
    expect(const BillingMonth(2026, 7).toIsoDay(), '2026-07-01');
    expect(const BillingMonth(2027, 11).toIsoDay(), '2027-11-01');
  });

  test('steps across the turn of the year in both directions', () {
    expect(const BillingMonth(2026, 12).next, const BillingMonth(2027, 1));
    expect(const BillingMonth(2027, 1).previous, const BillingMonth(2026, 12));
  });

  test('sorts by calendar order, not by month number alone', () {
    final sorted = BillingMonth.sorted(const [
      BillingMonth(2027, 1),
      BillingMonth(2026, 12),
      BillingMonth(2026, 2),
    ]);

    expect(sorted, const [
      BillingMonth(2026, 2),
      BillingMonth(2026, 12),
      BillingMonth(2027, 1),
    ]);
  });

  test('knows when two months are consecutive', () {
    expect(
      const BillingMonth(2026, 12).isRightBefore(const BillingMonth(2027, 1)),
      isTrue,
    );
    expect(
      const BillingMonth(2026, 10).isRightBefore(const BillingMonth(2026, 12)),
      isFalse,
    );
  });
}
