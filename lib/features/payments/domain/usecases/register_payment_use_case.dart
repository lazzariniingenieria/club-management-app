import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/billing_month.dart';
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

    final recorded = await repository.recordPayment(draft);
    final failure = recorded.getLeft().toNullable();
    if (failure is ConflictFailure) return _paidMeanwhile(draft, failure);

    return recorded;
  }

  Future<Either<Failure, void>> _paidMeanwhile(
    PaymentDraft draft,
    ConflictFailure conflict,
  ) async {
    final reread = await repository.loadPrecheck(draft.memberId);
    final paid = reread.fold(
      (_) => const <BillingMonth>[],
      (current) => draft.monthsAlreadyIn(current.paidMonths),
    );

    return Left(paid.isEmpty ? conflict : AlreadyPaidMonthsFailure(paid));
  }
}
