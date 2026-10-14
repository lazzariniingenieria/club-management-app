import 'package:equatable/equatable.dart';

import 'billing_month.dart';
import 'payment_method.dart';

class Payment extends Equatable {
  final int id;
  final int memberId;
  final int? paidByMemberId;
  final int amountCents;
  final BillingMonth month;
  final PaymentMethod method;
  final DateTime paidAt;
  final DateTime? voidedAt;
  final String? voidReason;

  const Payment({
    required this.id,
    required this.memberId,
    required this.amountCents,
    required this.month,
    required this.method,
    required this.paidAt,
    this.paidByMemberId,
    this.voidedAt,
    this.voidReason,
  });

  bool get isVoided => voidedAt != null;

  bool get wasPaidByAnotherMember =>
      paidByMemberId != null && paidByMemberId != memberId;

  @override
  List<Object?> get props => [
        id,
        memberId,
        paidByMemberId,
        amountCents,
        month,
        method,
        paidAt,
        voidedAt,
        voidReason,
      ];
}
