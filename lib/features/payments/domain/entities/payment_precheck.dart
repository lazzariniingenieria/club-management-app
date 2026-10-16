import 'package:equatable/equatable.dart';

import 'billing_month.dart';

class PaymentPrecheck extends Equatable {
  final bool isActive;
  final Set<BillingMonth> paidMonths;

  const PaymentPrecheck({required this.isActive, required this.paidMonths});

  bool get canRecordPayments => isActive;

  @override
  List<Object?> get props => [isActive, paidMonths];
}
