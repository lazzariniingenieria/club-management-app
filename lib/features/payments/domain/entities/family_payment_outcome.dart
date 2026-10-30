import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../failures/payment_failures.dart';
import 'billing_month.dart';

class FamilyPaymentOutcome extends Equatable {
  final Map<int, List<BillingMonth>> registered;
  final Map<int, Failure> failed;
  final Map<int, List<BillingMonth>> unconfirmed;

  const FamilyPaymentOutcome({
    this.registered = const {},
    this.failed = const {},
    this.unconfirmed = const {},
  });

  bool get isComplete => failed.isEmpty;

  bool get mayHaveLanded => unconfirmed.isNotEmpty;

  bool get groupMayHaveChanged => failed.values.any(
        (failure) =>
            failure is ValidationFailure || failure is InactiveMemberFailure,
      );

  @override
  List<Object?> get props => [registered, failed, unconfirmed];
}
