import 'package:equatable/equatable.dart';

import '../../../members/domain/entities/member.dart';
import '../../../payments/domain/entities/billing_month.dart';
import '../../../payments/domain/entities/payment.dart';

class MonthlyCollection extends Equatable {
  final BillingMonth month;
  final int totalCents;
  final int feeCount;

  const MonthlyCollection({
    required this.month,
    required this.totalCents,
    required this.feeCount,
  });

  @override
  List<Object?> get props => [month, totalCents, feeCount];
}

class ClubMetrics extends Equatable {
  final List<Payment> payments;
  final List<Member> members;

  const ClubMetrics({required this.payments, required this.members});

  MonthlyCollection collectionIn(BillingMonth month) {
    final collected = payments
        .where((payment) => !payment.isVoided)
        .where((payment) => BillingMonth.of(payment.paidAt.toLocal()) == month)
        .toList();

    return MonthlyCollection(
      month: month,
      totalCents: collected.fold(0, (sum, payment) => sum + payment.amountCents),
      feeCount: collected.length,
    );
  }

  List<MonthlyCollection> collectionsEndingIn(BillingMonth last, int count) {
    final months = [last];
    while (months.length < count) {
      months.insert(0, months.first.previous);
    }

    return [for (final month in months) collectionIn(month)];
  }

  int newMembersIn(BillingMonth month) => members
      .where((member) => member.joinedAt != null)
      .where((member) => BillingMonth.of(member.joinedAt!) == month)
      .length;

  int get overdueMembers =>
      members.where((member) => member.isActive && member.isOverdue).length;

  @override
  List<Object?> get props => [payments, members];
}
