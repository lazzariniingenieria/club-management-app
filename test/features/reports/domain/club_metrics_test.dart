import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/payment.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';
import 'package:club_management_app/features/reports/domain/entities/club_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

Payment payment(int id, DateTime paidAt, BillingMonth month, {bool voided = false}) =>
    Payment(
      id: id,
      memberId: 1,
      amountCents: 1500000,
      month: month,
      method: PaymentMethod.cash,
      paidAt: paidAt,
      voidedAt: voided ? DateTime(2026, 10, 20) : null,
    );

Member member(int id, {DateTime? joinedAt, int daysOverdue = 0, bool active = true}) =>
    Member(
      id: id,
      firstName: 'Socio',
      lastName: '$id',
      dni: '${30000000 + id}',
      status: active ? MemberStatus.active : MemberStatus.inactive,
      daysOverdue: daysOverdue,
      joinedAt: joinedAt,
    );

void main() {
  const september = BillingMonth(2026, 9);
  const october = BillingMonth(2026, 10);

  final metrics = ClubMetrics(
    payments: [
      payment(1, DateTime(2026, 10, 3), october),
      payment(2, DateTime(2026, 10, 3), september),
      payment(3, DateTime(2026, 10, 9), october, voided: true),
      payment(4, DateTime(2026, 9, 28), september),
    ],
    members: [
      member(1, joinedAt: DateTime(2026, 10, 2)),
      member(2, joinedAt: DateTime(2026, 9, 15), daysOverdue: 20),
      member(3, daysOverdue: 40, active: false),
    ],
  );

  test('counts what was collected in a month by the day it was paid', () {
    expect(
      metrics.collectionIn(october),
      const MonthlyCollection(month: october, totalCents: 3000000, feeCount: 2),
    );
  });

  test('leaves voided payments out', () {
    expect(metrics.collectionIn(october).feeCount, 2);
  });

  test('lists the months up to the one shown, oldest first', () {
    final months = metrics
        .collectionsEndingIn(october, 3)
        .map((collection) => collection.month);

    expect(months, [const BillingMonth(2026, 8), september, october]);
  });

  test('counts the members who joined in the month', () {
    expect(metrics.newMembersIn(october), 1);
    expect(metrics.newMembersIn(september), 1);
  });

  test('counts as overdue only active members behind on the fee', () {
    expect(metrics.overdueMembers, 1);
  });
}
