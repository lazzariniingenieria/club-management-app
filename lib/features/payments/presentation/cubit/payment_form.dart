import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../members/domain/entities/member.dart';
import '../../domain/entities/billing_month.dart';
import '../../domain/entities/family_payment_request.dart';
import '../../domain/entities/member_ledger.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_receipt.dart';
import 'family_payment.dart';

class PaymentForm extends Equatable {
  final MemberLedger ledger;
  final Set<BillingMonth> selectedMonths;
  final BillingMonth suggestedMonth;
  final int visibleYear;
  final int? amountCents;
  final PaymentMethod method;
  final int? payerId;
  final FamilyPayment? family;

  const PaymentForm({
    required this.ledger,
    required this.selectedMonths,
    required this.suggestedMonth,
    required this.visibleYear,
    required this.method,
    this.amountCents,
    this.payerId,
    this.family,
  });

  factory PaymentForm.start(MemberLedger ledger, DateTime today) {
    final suggested = ledger.suggestedMonth(today);

    return PaymentForm(
      ledger: ledger,
      selectedMonths: {suggested},
      suggestedMonth: suggested,
      visibleYear: suggested.year,
      method: PaymentMethod.cash,
      amountCents: ledger.monthlyFeeCents,
    );
  }

  List<BillingMonth> get months => BillingMonth.sorted(selectedMonths);

  int get totalCents => (amountCents ?? 0) * feeCount;

  int get feeCount => family == null
      ? selectedMonths.length
      : chargedMembers.fold(0, (sum, member) => sum + monthsFor(member).length);

  bool get canReview =>
      selectedMonths.isNotEmpty && (amountCents ?? 0) > 0 && _familyIsSettled;

  bool get startsFromLastPaid => ledger.lastPaidMonth != null;

  bool get paysForFamily => family != null;

  List<Member> get activeRelatives =>
      ledger.familyMembers.where((relative) => relative.isActive).toList();

  List<Member> get inactiveRelatives =>
      ledger.familyMembers.where((relative) => !relative.isActive).toList();

  List<int> get familyStatusIds =>
      [ledger.member.id, for (final relative in activeRelatives) relative.id];

  List<Member> get chargedMembers => [
        ledger.member,
        for (final relative in activeRelatives)
          if (family?.includes(relative.id) ?? false) relative,
      ];

  List<Member> get payingMembers =>
      chargedMembers.where((member) => monthsFor(member).isNotEmpty).toList();

  int get earliestYear {
    final joinedAt = ledger.member.joinedAt;
    final paid = BillingMonth.sorted(ledger.paidMonths);

    return [
      suggestedMonth.year,
      if (joinedAt != null) joinedAt.year,
      if (paid.isNotEmpty) paid.first.year,
    ].reduce(min);
  }

  bool get _familyIsSettled {
    final current = family;

    return current == null || (current.isReady && feeCount > 0);
  }

  bool isPaid(BillingMonth month) => ledger.paidMonths.contains(month);

  bool isSelected(BillingMonth month) => selectedMonths.contains(month);

  List<BillingMonth> monthsFor(Member member) {
    final paid = family?.paidMonthsOf(member.id) ?? const {};

    return months.where((month) => !paid.contains(month)).toList();
  }

  PaymentForm toggling(BillingMonth month) {
    if (isPaid(month)) return this;

    final next = {...selectedMonths};
    if (!next.remove(month)) next.add(month);

    return _with(selectedMonths: next);
  }

  PaymentForm withoutMonths(Iterable<BillingMonth> months) =>
      _with(selectedMonths: {...selectedMonths}..removeAll(months));

  PaymentForm showingYear(int year) =>
      _with(visibleYear: max(year, earliestYear));

  PaymentForm withAmount(int? cents) => PaymentForm(
        ledger: ledger,
        selectedMonths: selectedMonths,
        suggestedMonth: suggestedMonth,
        visibleYear: visibleYear,
        method: method,
        amountCents: cents,
        payerId: payerId,
        family: family,
      );

  PaymentForm withMethod(PaymentMethod value) => _with(method: value);

  PaymentForm withPayer(int? memberId) => PaymentForm(
        ledger: ledger,
        selectedMonths: selectedMonths,
        suggestedMonth: suggestedMonth,
        visibleYear: visibleYear,
        method: method,
        amountCents: amountCents,
        payerId: memberId,
        family: family,
      );

  PaymentForm withFamily(FamilyPayment? value) => PaymentForm(
        ledger: ledger,
        selectedMonths: selectedMonths,
        suggestedMonth: suggestedMonth,
        visibleYear: visibleYear,
        method: method,
        amountCents: amountCents,
        payerId: payerId,
        family: value,
      );

  PaymentForm withLedger(MemberLedger refreshed) {
    final stillUnpaid = selectedMonths
        .where((month) => !refreshed.paidMonths.contains(month))
        .toSet();
    final payerStillInGroup =
        refreshed.familyMembers.any((relative) => relative.id == payerId);

    return PaymentForm(
      ledger: refreshed,
      selectedMonths: stillUnpaid,
      suggestedMonth: suggestedMonth,
      visibleYear: visibleYear,
      method: method,
      amountCents: amountCents,
      payerId: payerStillInGroup ? payerId : null,
      family: family,
    );
  }

  PaymentDraft toDraft() {
    return PaymentDraft(
      memberId: ledger.member.id,
      months: months,
      amountCents: amountCents ?? 0,
      method: method,
      paidByMemberId: payerId,
    );
  }

  FamilyPaymentRequest toFamilyRequest() {
    return FamilyPaymentRequest(
      draft: toDraft(),
      relativeIds: [
        for (final member in chargedMembers.skip(1)) member.id,
      ],
    );
  }

  PaymentReceipt toReceipt() {
    return PaymentReceipt(
      memberId: ledger.member.id,
      months: months,
      totalCents: totalCents,
    );
  }

  PaymentReceipt toFamilyReceipt(Map<int, List<BillingMonth>> registered) {
    final fees = registered.values.fold(0, (sum, each) => sum + each.length);

    return PaymentReceipt(
      memberId: ledger.member.id,
      months: registered[ledger.member.id] ?? const [],
      totalCents: (amountCents ?? 0) * fees,
      familyMemberCount: registered.length,
    );
  }

  PaymentForm _with({
    Set<BillingMonth>? selectedMonths,
    int? visibleYear,
    PaymentMethod? method,
  }) {
    return PaymentForm(
      ledger: ledger,
      selectedMonths: selectedMonths ?? this.selectedMonths,
      suggestedMonth: suggestedMonth,
      visibleYear: visibleYear ?? this.visibleYear,
      method: method ?? this.method,
      amountCents: amountCents,
      payerId: payerId,
      family: family,
    );
  }

  @override
  List<Object?> get props => [
        ledger,
        selectedMonths,
        suggestedMonth,
        visibleYear,
        amountCents,
        method,
        payerId,
        family,
      ];
}
