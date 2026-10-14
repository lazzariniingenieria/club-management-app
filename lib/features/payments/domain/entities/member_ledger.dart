import 'package:equatable/equatable.dart';

import '../../../members/domain/entities/member.dart';
import 'billing_month.dart';
import 'payment.dart';

class MemberLedger extends Equatable {
  final Member member;
  final List<Member> familyMembers;
  final List<Payment> payments;
  final Map<int, String> memberNames;
  final int? monthlyFeeCents;

  const MemberLedger({
    required this.member,
    required this.payments,
    this.familyMembers = const [],
    this.memberNames = const {},
    this.monthlyFeeCents,
  });

  Iterable<Payment> get livePayments =>
      payments.where((payment) => !payment.isVoided);

  Set<BillingMonth> get paidMonths =>
      {for (final payment in livePayments) payment.month};

  BillingMonth? get lastPaidMonth {
    final months = BillingMonth.sorted(paidMonths);

    return months.isEmpty ? null : months.last;
  }

  bool get hasNeverPaid => paidMonths.isEmpty;

  bool get canRecordPayments => member.isActive;

  BillingMonth suggestedMonth(DateTime today) {
    final lastPaid = lastPaidMonth;
    if (lastPaid != null) return lastPaid.next;

    return BillingMonth.of(member.joinedAt ?? today);
  }

  String? nameOf(int memberId) => memberNames[memberId];

  @override
  List<Object?> get props =>
      [member, familyMembers, payments, memberNames, monthlyFeeCents];
}
