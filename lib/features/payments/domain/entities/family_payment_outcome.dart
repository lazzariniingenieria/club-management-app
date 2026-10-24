import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import 'billing_month.dart';

class FamilyPaymentOutcome extends Equatable {
  final Map<int, List<BillingMonth>> registered;
  final Map<int, Failure> failed;

  const FamilyPaymentOutcome({
    this.registered = const {},
    this.failed = const {},
  });

  bool get isComplete => failed.isEmpty;

  bool get mayHaveLanded =>
      failed.values.any((failure) => failure is ResponseTimeoutFailure);

  @override
  List<Object?> get props => [registered, failed];
}
