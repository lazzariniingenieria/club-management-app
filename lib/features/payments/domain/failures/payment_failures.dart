import '../../../../core/errors/failures.dart';
import '../entities/billing_month.dart';

class AlreadyPaidMonthsFailure extends Failure {
  final List<BillingMonth> months;

  const AlreadyPaidMonthsFailure(this.months)
      : super('Some months were already paid');

  @override
  List<Object?> get props => [message, months];
}

class InactiveMemberFailure extends Failure {
  const InactiveMemberFailure() : super('The member is no longer active');
}
