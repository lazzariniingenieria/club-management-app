import '../../../members/domain/entities/member.dart';
import '../../domain/entities/family_payment_outcome.dart';
import 'family_payment.dart';
import 'payment_form.dart';
import 'register_payment_state.dart';

class FamilySettlement {
  final PaymentForm sent;
  final PaymentForm settled;
  final FamilyPaymentOutcome outcome;

  const FamilySettlement({
    required this.sent,
    required this.settled,
    required this.outcome,
  });

  FamilyPayment get _family => settled.family ?? const FamilyPayment();

  List<Member> get left => sent
      .relativesMissingIn(settled)
      .where((relative) => outcome.failed.containsKey(relative.id))
      .toList();

  List<int> get pendingIds {
    final leftIds = {for (final relative in left) relative.id};

    return [
      for (final id in outcome.failed.keys)
        if (!_family.registered.containsKey(id) && !leftIds.contains(id)) id,
    ];
  }

  bool get payerLeft => sent.payerId != null && settled.payerId == null;

  bool get _hasNothingLeftToCharge => pendingIds.isEmpty && left.isEmpty;

  RegisterPaymentState toState() {
    if (pendingIds.isEmpty && _family.registered.isNotEmpty) {
      return RegisterPaymentRegistered(
        settled.toFamilyReceipt(leftOutNames: _leftNames),
      );
    }

    return RegisterPaymentEditing(form: settled, notice: _notice());
  }

  RegisterPaymentNotice _notice() {
    if (_hasNothingLeftToCharge) return const FamilyAlreadyPaidNotice();
    if (payerLeft && !_family.hasProgress) return const PayerLeftGroupNotice();

    return FamilyPaymentIncompleteNotice(
      registeredIds: _family.registered.keys.toList(),
      pendingIds: pendingIds,
      mayHaveLanded: _mayHaveLanded,
      leftNames: _leftNames,
      payerLeft: payerLeft,
    );
  }

  List<String> get _leftNames =>
      [for (final relative in left) relative.fullName];

  bool get _mayHaveLanded => _family.hasUnconfirmed || outcome.mayHaveLanded;
}
