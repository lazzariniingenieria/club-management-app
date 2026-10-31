import 'package:equatable/equatable.dart';

import 'billing_month.dart';
import 'payment_draft.dart';

class FamilyPaymentRequest extends Equatable {
  final PaymentDraft draft;
  final List<int> relativeIds;

  const FamilyPaymentRequest({required this.draft, required this.relativeIds});

  List<int> get memberIds => [draft.memberId, ...relativeIds];

  int get payerId => draft.paidByMemberId ?? draft.memberId;

  PaymentDraft draftFor(int memberId, Set<BillingMonth> paidMonths) {
    return PaymentDraft(
      memberId: memberId,
      months:
          draft.months.where((month) => !paidMonths.contains(month)).toList(),
      amountCents: draft.amountCents,
      method: draft.method,
      paidByMemberId: payerId == memberId ? null : payerId,
    );
  }

  @override
  List<Object?> get props => [draft, relativeIds];
}
