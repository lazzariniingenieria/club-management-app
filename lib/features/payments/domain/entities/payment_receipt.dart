import 'package:equatable/equatable.dart';

import 'billing_month.dart';

class PaymentReceipt extends Equatable {
  final int memberId;
  final List<BillingMonth> months;
  final int totalCents;

  const PaymentReceipt({
    required this.memberId,
    required this.months,
    required this.totalCents,
  });

  @override
  List<Object?> get props => [memberId, months, totalCents];
}
