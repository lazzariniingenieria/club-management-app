import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_precheck.dart';
import 'package:club_management_app/features/payments/presentation/cubit/family_payment.dart';
import 'package:club_management_app/features/payments/presentation/cubit/payment_form.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/payment_builders.dart';

void main() {
  const september = BillingMonth(2026, 9);
  const october = BillingMonth(2026, 10);

  PaymentForm familyForm({Set<BillingMonth> months = const {}}) {
    return PaymentForm(
      ledger: buildLedger(
        familyMembers: [
          buildLedgerMember(id: 2, firstName: 'María'),
          buildLedgerMember(id: 3, firstName: 'Luis'),
        ],
      ),
      selectedMonths: months,
      suggestedMonth: september,
      visibleYear: 2026,
      method: PaymentMethod.cash,
      amountCents: feeCents,
      family: const FamilyPayment(),
    );
  }

  group('the receipt of a payment for the whole group', () {
    test('multiplies the amount of one month by every fee registered', () {
      final receipt = familyForm().toFamilyReceipt({
        1: [september],
        2: [september, october],
      });

      expect(receipt.totalCents, 3 * feeCents);
      expect(receipt.familyMemberCount, 2);
      expect(receipt.months, [september]);
    });

    test('names the relatives who were left out of the payment', () {
      final receipt = familyForm().toFamilyReceipt({
        1: [september],
      }, skippedIds: [2]);

      expect(receipt.leftOutNames, ['María Álvarez']);
    });

    test('has no months of its own when the member had them paid', () {
      final receipt = familyForm().toFamilyReceipt({
        2: [september],
      });

      expect(receipt.months, isEmpty);
      expect(receipt.familyMemberCount, 1);
    });
  });

  group('choosing who is charged', () {
    test('every active relative starts chosen', () {
      final form = familyForm();

      expect(form.chargedMembers.map((member) => member.id), [1, 2, 3]);
    });

    test('a relative can be left out and brought back at any time', () {
      final left = familyForm().withFamily(
        familyForm().family!.toggling(2),
      );
      final back = left.withFamily(left.family!.toggling(2));

      expect(left.chargedMembers.map((member) => member.id), [1, 3]);
      expect(back.chargedMembers.map((member) => member.id), [1, 2, 3]);
    });

    test('a month a member already paid is not charged again', () {
      final form = familyForm(months: {september, october})
          .withFamilyHistory({
        1: const PaymentPrecheck(isActive: true, paidMonths: {}),
        2: PaymentPrecheck(isActive: true, paidMonths: {september}),
        3: const PaymentPrecheck(isActive: true, paidMonths: {}),
      });

      expect(form.monthsFor(form.ledger.familyMembers.first), [october]);
      expect(form.feeCount, 5);
    });
  });
}
