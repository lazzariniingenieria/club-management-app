import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/family_payment_outcome.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_precheck.dart';
import 'package:club_management_app/features/payments/presentation/cubit/family_payment.dart';
import 'package:club_management_app/features/payments/presentation/cubit/payment_form.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/payment_builders.dart';

void main() {
  const september = BillingMonth(2026, 9);
  const october = BillingMonth(2026, 10);

  PaymentPrecheck paidOf(Set<BillingMonth> months) =>
      PaymentPrecheck(isActive: true, paidMonths: months);

  group('registering fees at different amounts', () {
    test('the receipt adds what each fee really cost', () {
      final form = PaymentForm.start(
        buildLedger(familyMembers: [buildLedgerMember(id: 2)]),
        DateTime(2026, 10, 14),
      ).withFamily(
        const FamilyPayment(
          registered: {
            1: RegisteredFee(months: [september], amountCents: 1500000),
            2: RegisteredFee(
              months: [september, october],
              amountCents: 1200000,
            ),
          },
        ),
      );

      final receipt = form.toFamilyReceipt();

      expect(receipt.totalCents, 1500000 + 2 * 1200000);
      expect(receipt.familyMemberCount, 2);
      expect(receipt.months, [september]);
    });

    test('a submit stores the amount the form had when it was sent', () {
      const outcome = FamilyPaymentOutcome(
        registered: {
          2: [september],
        },
      );

      final family = const FamilyPayment().afterSubmit(
        outcome,
        amountCents: 1200000,
      );

      expect(family.registered[2]?.amountCents, 1200000);
      expect(family.registered[2]?.totalCents, 1200000);
    });
  });

  group('timeouts', () {
    const timedOut = FamilyPaymentOutcome(
      failed: {2: ResponseTimeoutFailure()},
      unconfirmed: {
        2: [september],
      },
    );

    FamilyPayment afterTimeout() =>
        const FamilyPayment().afterSubmit(timedOut, amountCents: 1500000);

    test('keep the months that may have landed and lock the charge', () {
      final family = afterTimeout();

      expect(family.unconfirmed, {
        2: [september],
      });
      expect(family.hasProgress, isTrue);
      expect(family.hasSettled(2), isTrue);
    });

    test('become registered once the history shows every month paid', () {
      final family = afterTimeout()
          .loaded({2: paidOf({september})}).confirmingLanded(amountCents: 1500000);

      expect(family.unconfirmed, isEmpty);
      expect(family.registered[2]?.months, [september]);
    });

    test('stay unconfirmed while the history misses a month', () {
      final family = afterTimeout()
          .loaded({2: paidOf({october})}).confirmingLanded(amountCents: 1500000);

      expect(family.unconfirmed.keys, [2]);
      expect(family.registered, isEmpty);
    });

    test('are dropped once a later submit registers that member', () {
      const retried = FamilyPaymentOutcome(
        registered: {
          2: [september],
        },
      );

      final family = afterTimeout().afterSubmit(retried, amountCents: 1500000);

      expect(family.unconfirmed, isEmpty);
      expect(family.registered.keys, [2]);
    });
  });
}
