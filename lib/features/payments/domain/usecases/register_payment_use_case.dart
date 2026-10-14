import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member_ledger.dart';
import '../entities/payment_draft.dart';
import '../failures/payment_failures.dart';
import '../repositories/payment_repository.dart';

class RegisterPaymentUseCase {
  final PaymentRepository repository;

  RegisterPaymentUseCase(this.repository);

  Future<Either<Failure, void>> call(PaymentDraft draft) async {
    final ledger = await repository.loadLedger(draft.memberId);

    return ledger.fold<Future<Either<Failure, void>>>(
      (failure) async => Left(failure),
      (current) => _recordUnlessAlreadyPaid(draft, current),
    );
  }

  Future<Either<Failure, void>> _recordUnlessAlreadyPaid(
    PaymentDraft draft,
    MemberLedger ledger,
  ) async {
    if (!ledger.canRecordPayments) return const Left(InactiveMemberFailure());

    final alreadyPaid = draft.monthsAlreadyIn(ledger.paidMonths);
    if (alreadyPaid.isNotEmpty) {
      return Left(AlreadyPaidMonthsFailure(alreadyPaid));
    }

    return repository.recordPayment(draft);
  }
}
