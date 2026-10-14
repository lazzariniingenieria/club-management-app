import 'package:club_management_app/features/payments/data/models/payment_model.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_draft.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const row = <String, dynamic>{
    'id': 88,
    'memberId': 34,
    'paidByMemberId': null,
    'amount': 15000.00,
    'paidAt': '2026-07-05T13:00:00Z',
    'periodCovered': '2026-07-01',
    'paymentMethod': 'TRANSFER',
    'recordedByUserId': 12,
    'createdAt': '2026-07-05T13:00:00Z',
    'voidedAt': null,
    'voidedByUserId': null,
    'voidReason': null,
  };

  group('reading a payment', () {
    test('keeps the amount in cents, never as a double', () {
      final payment = PaymentModel.fromJson(row);

      expect(payment.amountCents, 1500000);
      expect(PaymentModel.fromJson({...row, 'amount': 14999.9}).amountCents,
          1499990);
    });

    test('maps the month, the method and who paid', () {
      final payment = PaymentModel.fromJson({...row, 'paidByMemberId': 35});

      expect(payment.month, const BillingMonth(2026, 7));
      expect(payment.method, PaymentMethod.transfer);
      expect(payment.wasPaidByAnotherMember, isTrue);
    });

    test('reads a voided payment with its reason', () {
      final payment = PaymentModel.fromJson({
        ...row,
        'voidedAt': '2026-10-14T15:00:00Z',
        'voidedByUserId': 12,
        'voidReason': 'Se cargó en el socio equivocado',
      });

      expect(payment.isVoided, isTrue);
      expect(payment.voidReason, 'Se cargó en el socio equivocado');
    });
  });

  group('writing a payment', () {
    const draft = PaymentDraft(
      memberId: 34,
      months: [BillingMonth(2026, 10), BillingMonth(2026, 9)],
      amountCents: 1500000,
      method: PaymentMethod.cash,
    );

    test('sends the amount of one month, not the total', () {
      final body = PaymentModel.bodyFromDraft(draft);

      expect(body['amount'], 15000);
      expect(draft.totalCents, 3000000);
    });

    test('sends every month as its first day, in calendar order', () {
      final body = PaymentModel.bodyFromDraft(draft);

      expect(body['periodsCovered'], ['2026-09-01', '2026-10-01']);
      expect(body['paymentMethod'], 'CASH');
      expect(body['paidByMemberId'], isNull);
    });
  });
}
