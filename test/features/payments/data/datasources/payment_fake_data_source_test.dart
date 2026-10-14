import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:club_management_app/features/payments/data/datasources/payment_fake_data_source.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_draft.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 14);
  late MemberFakeDataSource members;
  late PaymentFakeDataSource payments;
  final reported = <int, int>{};

  final overdueMember = MemberFakeDataSource.roster.firstWhere(
    (member) => member.isOverdue && member.familyGroupId == null,
  );

  setUp(() {
    reported.clear();
    members = MemberFakeDataSource(latency: Duration.zero);
    payments = PaymentFakeDataSource(
      members: members,
      latency: Duration.zero,
      clock: () => today,
      onDelinquencyChanged: (memberId, days) {
        reported[memberId] = days;
        members.setDaysOverdue(memberId, days);
      },
    );
  });

  test('seeds a history that matches the mora of the roster', () async {
    final ledger = await payments.fetchLedger(overdueMember.id);

    expect(ledger.payments, isNotEmpty);
    expect(ledger.suggestedMonth(today).firstDay.isAfter(today), isFalse);
  });

  test('paying up to the current month leaves the member up to date', () async {
    final ledger = await payments.fetchLedger(overdueMember.id);
    final months = <BillingMonth>[];
    for (var month = ledger.suggestedMonth(today);
        !BillingMonth.of(today).isBefore(month);
        month = month.next) {
      months.add(month);
    }

    await payments.recordPayment(
      PaymentDraft(
        memberId: overdueMember.id,
        months: months,
        amountCents: PaymentFakeDataSource.defaultMonthlyFeeCents,
        method: PaymentMethod.cash,
      ),
    );

    expect(reported[overdueMember.id], 0);
    final roster = await members.fetchMembers();
    expect(
      roster.firstWhere((member) => member.id == overdueMember.id).isOverdue,
      isFalse,
    );
  });

  test('rejects a payer from outside the family group, as the API does', () {
    final stranger = MemberFakeDataSource.roster.last;

    expect(
      payments.recordPayment(
        PaymentDraft(
          memberId: overdueMember.id,
          months: const [BillingMonth(2026, 11)],
          amountCents: PaymentFakeDataSource.defaultMonthlyFeeCents,
          method: PaymentMethod.cash,
          paidByMemberId: stranger.id,
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('voiding twice is a conflict, as the API does', () async {
    final ledger = await payments.fetchLedger(overdueMember.id);
    final paymentId = ledger.payments.first.id;

    await payments.voidPayment(paymentId, reason: 'Error de carga');

    expect(
      payments.voidPayment(paymentId),
      throwsA(isA<ConflictException>()),
    );
  });

  test('voiding the last month puts the member back in mora', () async {
    final ledger = await payments.fetchLedger(overdueMember.id);

    await payments.voidPayment(ledger.payments.first.id);

    expect(reported[overdueMember.id], greaterThan(overdueMember.daysOverdue));
  });
}
