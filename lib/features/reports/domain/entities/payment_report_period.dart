import 'package:equatable/equatable.dart';

import '../../../payments/domain/entities/billing_month.dart';

class PaymentReportPeriod extends Equatable {
  final BillingMonth from;
  final BillingMonth to;

  const PaymentReportPeriod({required this.from, required this.to});

  const PaymentReportPeriod.single(BillingMonth month)
      : from = month,
        to = month;

  bool get isValid => !to.isBefore(from);

  bool get isSingleMonth => from == to;

  DateTime get firstDay => from.firstDay;

  DateTime get lastDay => DateTime(to.year, to.month + 1, 0);

  @override
  List<Object?> get props => [from, to];
}
