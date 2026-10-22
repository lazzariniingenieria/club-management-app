import 'package:equatable/equatable.dart';

import 'billing_month.dart';
import 'payment_method.dart';

class PaymentDraft extends Equatable {
  final int memberId;
  final List<BillingMonth> months;
  final int amountCents;
  final PaymentMethod method;
  final int? paidByMemberId;

  const PaymentDraft({
    required this.memberId,
    required this.months,
    required this.amountCents,
    required this.method,
    this.paidByMemberId,
  });

  int get totalCents => amountCents * months.length;

  List<BillingMonth> monthsAlreadyIn(Set<BillingMonth> paidMonths) =>
      months.where(paidMonths.contains).toList();

  @override
  List<Object?> get props =>
      [memberId, months, amountCents, method, paidByMemberId];
}
