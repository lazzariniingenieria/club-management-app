import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import 'billing_month.dart';

sealed class FamilyPaymentOutcome extends Equatable {
  const FamilyPaymentOutcome();

  @override
  List<Object?> get props => [];
}

class FamilyPaymentRegistered extends FamilyPaymentOutcome {
  final Map<int, List<BillingMonth>> months;
  final List<int> skippedIds;

  const FamilyPaymentRegistered({
    required this.months,
    this.skippedIds = const [],
  });

  @override
  List<Object?> get props => [months, skippedIds];
}

class FamilyPaymentNothingToCharge extends FamilyPaymentOutcome {
  final List<int> skippedIds;

  const FamilyPaymentNothingToCharge({this.skippedIds = const []});

  @override
  List<Object?> get props => [skippedIds];
}

class FamilyPaymentUnconfirmed extends FamilyPaymentOutcome {
  final Map<int, List<BillingMonth>> months;
  final List<int> skippedIds;

  const FamilyPaymentUnconfirmed({
    required this.months,
    this.skippedIds = const [],
  });

  @override
  List<Object?> get props => [months, skippedIds];
}

class FamilyPaymentRejected extends FamilyPaymentOutcome {
  final Failure failure;

  const FamilyPaymentRejected(this.failure);

  @override
  List<Object?> get props => [failure];
}
