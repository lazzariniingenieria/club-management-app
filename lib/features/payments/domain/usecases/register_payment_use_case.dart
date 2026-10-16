import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/payment_draft.dart';
import '../entities/payment_precheck.dart';
import '../failures/payment_failures.dart';
import '../repositories/payment_repository.dart';

class RegisterPaymentUseCase {
  final PaymentRepository repository;

  RegisterPaymentUseCase(this.repository);

  Future<Either<Failure, void>> call(PaymentDraft draft) async {
    final precheck = await repository.loadPrecheck(draft.memberId);

    return precheck.fold<Future<Either<Failure, void>>>(
      (failure) async => Left(failure),
      (current) => _recordUnlessAlreadyPaid(draft, current),
    );
  }

  Future<Either<Failure, void>> _recordUnlessAlreadyPaid(
    PaymentDraft draft,
    PaymentPrecheck precheck,
  ) async {
    if (!precheck.canRecordPayments) {
      return const Left(InactiveMemberFailure());
    }

    final alreadyPaid = draft.monthsAlreadyIn(precheck.paidMonths);
    if (alreadyPaid.isNotEmpty) {
      return Left(AlreadyPaidMonthsFailure(alreadyPaid));
    }

    return repository.recordPayment(draft);
  }
}
