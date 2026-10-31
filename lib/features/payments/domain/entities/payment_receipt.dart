import 'package:equatable/equatable.dart';

import 'billing_month.dart';

class PaymentReceipt extends Equatable {
  final int memberId;
  final List<BillingMonth> months;
  final int totalCents;
  final int? familyMemberCount;
  final List<String> leftOutNames;

  const PaymentReceipt({
    required this.memberId,
    required this.months,
    required this.totalCents,
    this.familyMemberCount,
    this.leftOutNames = const [],
  });

  @override
  List<Object?> get props =>
      [memberId, months, totalCents, familyMemberCount, leftOutNames];
}
