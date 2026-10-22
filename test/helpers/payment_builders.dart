import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/payments/data/models/payment_model.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/member_ledger.dart';
import 'package:club_management_app/features/payments/domain/entities/payment.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';

const int feeCents = 1500000;

Member buildLedgerMember({
  int id = 1,
  String firstName = 'Juan',
  String lastName = 'Álvarez',
  int daysOverdue = 43,
  MemberStatus status = MemberStatus.active,
  int? familyGroupId,
  DateTime? joinedAt,
}) {
  return Member(
    id: id,
    firstName: firstName,
    lastName: lastName,
    dni: '${35120000 + id}',
    status: status,
    daysOverdue: daysOverdue,
    familyGroupId: familyGroupId,
    joinedAt: joinedAt ?? DateTime(2024, 3, 15),
  );
}

Payment buildPayment({
  required int id,
  required BillingMonth month,
  int memberId = 1,
  int amountCents = feeCents,
  int? paidByMemberId,
  DateTime? voidedAt,
  String? voidReason,
}) {
  return PaymentModel(
    id: id,
    memberId: memberId,
    paidByMemberId: paidByMemberId,
    amountCents: amountCents,
    month: month,
    method: PaymentMethod.cash,
    paidAt: month.firstDay.add(const Duration(days: 4)),
    voidedAt: voidedAt,
    voidReason: voidReason,
  );
}

MemberLedger buildLedger({
  Member? member,
  List<Payment>? payments,
  List<Member> familyMembers = const [],
  int? monthlyFeeCents = feeCents,
}) {
  final owner = member ?? buildLedgerMember();

  return MemberLedger(
    member: owner,
    payments: payments ??
        [
          buildPayment(id: 2, month: const BillingMonth(2026, 8)),
          buildPayment(id: 1, month: const BillingMonth(2026, 7)),
        ],
    familyMembers: familyMembers,
    memberNames: {
      owner.id: owner.fullName,
      for (final relative in familyMembers) relative.id: relative.fullName,
    },
    monthlyFeeCents: monthlyFeeCents,
  );
}
