import '../../../../core/errors/exceptions.dart';
import '../../../members/data/models/member_model.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/member_ledger.dart';
import '../../domain/entities/payment.dart';
import 'payment_model.dart';

class MemberLedgerModel extends MemberLedger {
  const MemberLedgerModel({
    required super.member,
    required super.payments,
    super.familyMembers,
    super.memberNames,
    super.monthlyFeeCents,
  });

  factory MemberLedgerModel.fromResponses({
    required int memberId,
    required List<dynamic> members,
    required List<dynamic> delinquency,
    required List<dynamic> payments,
  }) {
    final roster = MemberModel.listFromResponses(
      members: members,
      delinquency: delinquency,
    );

    return MemberLedgerModel.fromRoster(
      memberId: memberId,
      roster: roster,
      payments: PaymentModel.listFromJson(payments),
    );
  }

  factory MemberLedgerModel.fromRoster({
    required int memberId,
    required List<Member> roster,
    required List<Payment> payments,
  }) {
    final member = _find(memberId, roster);

    return MemberLedgerModel(
      member: member,
      familyMembers: roster.where(member.sharesFamilyGroupWith).toList(),
      payments: newestFirst(payments),
      memberNames: {for (final each in roster) each.id: each.fullName},
    );
  }

  static List<Payment> newestFirst(List<Payment> payments) {
    return [...payments]..sort(_newestFirst);
  }

  static int _newestFirst(Payment a, Payment b) {
    final byMonth = b.month.compareTo(a.month);

    return byMonth != 0 ? byMonth : b.paidAt.compareTo(a.paidAt);
  }

  static Member _find(int memberId, List<Member> roster) {
    for (final member in roster) {
      if (member.id == memberId) return member;
    }

    throw NotFoundException('Member $memberId is not in the club');
  }
}
