import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../domain/entities/billing_month.dart';
import '../../domain/entities/member_ledger.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_receipt.dart';

class PaymentForm extends Equatable {
  final MemberLedger ledger;
  final Set<BillingMonth> selectedMonths;
  final BillingMonth suggestedMonth;
  final int visibleYear;
  final int? amountCents;
  final PaymentMethod method;
  final int? payerId;

  const PaymentForm({
    required this.ledger,
    required this.selectedMonths,
    required this.suggestedMonth,
    required this.visibleYear,
    required this.method,
    this.amountCents,
    this.payerId,
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

  int get totalCents => (amountCents ?? 0) * selectedMonths.length;

  bool get canReview => selectedMonths.isNotEmpty && (amountCents ?? 0) > 0;

  bool get startsFromLastPaid => ledger.lastPaidMonth != null;

  int get earliestYear {
    final joinedAt = ledger.member.joinedAt;
    final paid = BillingMonth.sorted(ledger.paidMonths);

    return [
      suggestedMonth.year,
      if (joinedAt != null) joinedAt.year,
      if (paid.isNotEmpty) paid.first.year,
    ].reduce(min);
  }

  bool isPaid(BillingMonth month) => ledger.paidMonths.contains(month);

  bool isSelected(BillingMonth month) => selectedMonths.contains(month);

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

  PaymentReceipt toReceipt() {
    return PaymentReceipt(
      memberId: ledger.member.id,
      months: months,
      totalCents: totalCents,
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
      ];
}
