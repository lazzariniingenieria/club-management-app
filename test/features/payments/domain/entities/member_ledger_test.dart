import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/payment_builders.dart';

void main() {
  final today = DateTime(2026, 10, 14);

  test('the last paid month is the latest one, not the latest loaded', () {
    final ledger = buildLedger(
      payments: [
        buildPayment(id: 1, month: const BillingMonth(2026, 1)),
        buildPayment(id: 2, month: const BillingMonth(2026, 12)),
      ],
    );

    expect(ledger.lastPaidMonth, const BillingMonth(2026, 12));
  });

  test('a voided payment no longer counts as paid', () {
    final ledger = buildLedger(
      payments: [
        buildPayment(
          id: 2,
          month: const BillingMonth(2026, 8),
          voidedAt: DateTime.utc(2026, 10, 14),
        ),
        buildPayment(id: 1, month: const BillingMonth(2026, 7)),
      ],
    );

    expect(ledger.lastPaidMonth, const BillingMonth(2026, 7));
    expect(ledger.paidMonths, {const BillingMonth(2026, 7)});
  });

  test('suggests the month that follows the last one paid', () {
    expect(buildLedger().suggestedMonth(today), const BillingMonth(2026, 9));
  });

  test('suggests the month of joining when the member never paid', () {
    final ledger = buildLedger(
      member: buildLedgerMember(joinedAt: DateTime(2026, 3, 15)),
      payments: const [],
    );

    expect(ledger.hasNeverPaid, isTrue);
    expect(ledger.suggestedMonth(today), const BillingMonth(2026, 3));
  });
}
