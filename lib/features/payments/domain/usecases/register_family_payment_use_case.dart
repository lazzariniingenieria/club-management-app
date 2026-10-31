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
    final ids = request.memberIds;
    final prechecks = await Future.wait(ids.map(repository.loadPrecheck));
    final unreadable = _firstFailure(prechecks);
    if (unreadable != null) return FamilyPaymentRejected(unreadable);

    final current = {
      for (var index = 0; index < ids.length; index++)
        ids[index]: prechecks[index].getRight().toNullable()!,
    };
    if (!current[request.draft.memberId]!.canRecordPayments) {
      return const FamilyPaymentRejected(InactiveMemberFailure());
    }

    return _send(request, current);
  }

  static Failure? _firstFailure(
    List<Either<Failure, PaymentPrecheck>> prechecks,
  ) {
    for (final precheck in prechecks) {
      final failure = precheck.getLeft().toNullable();
      if (failure != null) return failure;
    }

    return null;
  }

  Future<FamilyPaymentOutcome> _send(
    FamilyPaymentRequest request,
    Map<int, PaymentPrecheck> current,
  ) async {
    final skippedIds = [
      for (final MapEntry(:key, :value) in current.entries)
        if (!value.canRecordPayments) key,
    ];
    final drafts = [
      for (final MapEntry(:key, :value) in current.entries)
        if (value.canRecordPayments)
          request.draftFor(key, value.paidMonths),
    ].where((draft) => draft.months.isNotEmpty).toList();
    if (drafts.isEmpty) {
      return FamilyPaymentNothingToCharge(skippedIds: skippedIds);
    }

    final result = await repository.recordPayments(drafts);
    final months = {for (final draft in drafts) draft.memberId: draft.months};
    final failure = result.getLeft().toNullable();
    if (failure == null) {
      return FamilyPaymentRegistered(months: months, skippedIds: skippedIds);
    }
    if (failure is! ResponseTimeoutFailure) return FamilyPaymentRejected(failure);

    return _confirmed(drafts, months, skippedIds);
  }

  Future<FamilyPaymentOutcome> _confirmed(
    List<PaymentDraft> drafts,
    Map<int, List<BillingMonth>> months,
    List<int> skippedIds,
  ) async {
    final histories = await Future.wait(
      drafts.map((draft) => repository.loadPrecheck(draft.memberId)),
    );
    final allLanded = [
      for (var index = 0; index < drafts.length; index++)
        histories[index].fold(
          (_) => false,
          (history) => history.paidMonths.containsAll(drafts[index].months),
        ),
    ].every((landed) => landed);

    return allLanded
        ? FamilyPaymentRegistered(months: months, skippedIds: skippedIds)
        : FamilyPaymentUnconfirmed(months: months, skippedIds: skippedIds);
  }
}
