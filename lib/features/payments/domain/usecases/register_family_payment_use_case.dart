import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/billing_month.dart';
import '../entities/family_payment_outcome.dart';
import '../entities/family_payment_request.dart';
import '../entities/payment_draft.dart';
import '../entities/payment_precheck.dart';
import '../failures/payment_failures.dart';
import '../repositories/payment_repository.dart';

class RegisterFamilyPaymentUseCase {
  final PaymentRepository repository;

  RegisterFamilyPaymentUseCase(this.repository);

  Future<FamilyPaymentOutcome> call(FamilyPaymentRequest request) async {
    final planned = await _plannedDrafts(request);
    final failed = {
      for (final MapEntry(key: memberId, value: plan) in planned.entries)
        if (plan.getLeft().toNullable() case final failure?) memberId: failure,
    };
    final drafts = [
      for (final plan in planned.values)
        if (plan.getRight().toNullable() case final draft?) draft,
    ];
    final results = await repository.recordPayments(drafts);

    return _settle(drafts, results, failed);
  }

  Future<Map<int, Either<Failure, PaymentDraft?>>> _plannedDrafts(
    FamilyPaymentRequest request,
  ) async {
    final ids = request.memberIds;
    final prechecks = await Future.wait(ids.map(repository.loadPrecheck));

    return {
      for (var index = 0; index < ids.length; index++)
        ids[index]: _draftFrom(request, ids[index], prechecks[index]),
    };
  }

  static Either<Failure, PaymentDraft?> _draftFrom(
    FamilyPaymentRequest request,
    int memberId,
    Either<Failure, PaymentPrecheck> precheck,
  ) {
    return precheck.flatMap((current) {
      if (!current.canRecordPayments) {
        return const Left(InactiveMemberFailure());
      }
      final draft = request.draftFor(memberId, current.paidMonths);

      return Right(draft.months.isEmpty ? null : draft);
    });
  }

  Future<FamilyPaymentOutcome> _settle(
    List<PaymentDraft> drafts,
    List<Either<Failure, void>> results,
    Map<int, Failure> failed,
  ) async {
    final registered = <int, List<BillingMonth>>{};
    final unsettled = {...failed};
    for (var index = 0; index < drafts.length; index++) {
      final draft = drafts[index];
      final failure = await _unsettledFailure(draft, results[index]);
      if (failure != null) {
        unsettled[draft.memberId] = failure;
      } else if (results[index].isRight()) {
        registered[draft.memberId] = draft.months;
      }
    }

    return FamilyPaymentOutcome(registered: registered, failed: unsettled);
  }

  Future<Failure?> _unsettledFailure(
    PaymentDraft draft,
    Either<Failure, void> result,
  ) async {
    final failure = result.getLeft().toNullable();
    if (failure is! ConflictFailure) return failure;

    final reread = await repository.loadPrecheck(draft.memberId);
    final stillUnpaid = reread.fold<Iterable<BillingMonth>>(
      (_) => draft.months,
      (current) => draft.months.where((m) => !current.paidMonths.contains(m)),
    );

    return stillUnpaid.isEmpty ? null : failure;
  }
}
