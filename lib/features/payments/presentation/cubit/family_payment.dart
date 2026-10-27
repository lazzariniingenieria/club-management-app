import 'package:equatable/equatable.dart';

import '../../domain/entities/billing_month.dart';
import '../../domain/entities/family_payment_outcome.dart';
import '../../domain/entities/payment_precheck.dart';

enum FamilyStatusLoad { loading, loaded, failed }

class RegisteredFee extends Equatable {
  final List<BillingMonth> months;
  final int amountCents;

  const RegisteredFee({required this.months, required this.amountCents});

  int get totalCents => amountCents * months.length;

  @override
  List<Object?> get props => [months, amountCents];
}

class FamilyPayment extends Equatable {
  final FamilyStatusLoad load;
  final Map<int, PaymentPrecheck> statuses;
  final Set<int> excludedIds;
  final Map<int, RegisteredFee> registered;
  final Map<int, List<BillingMonth>> unconfirmed;

  const FamilyPayment({
    this.load = FamilyStatusLoad.loading,
    this.statuses = const {},
    this.excludedIds = const {},
    this.registered = const {},
    this.unconfirmed = const {},
  });

  bool get isLoading => load == FamilyStatusLoad.loading;

  bool get isReady => load == FamilyStatusLoad.loaded;

  bool get failedToLoad => load == FamilyStatusLoad.failed;

  bool get hasProgress => registered.isNotEmpty || unconfirmed.isNotEmpty;

  bool get hasUnconfirmed => unconfirmed.isNotEmpty;

  bool includes(int memberId) => !excludedIds.contains(memberId);

  bool hasSettled(int memberId) =>
      registered.containsKey(memberId) || unconfirmed.containsKey(memberId);

  Set<BillingMonth> paidMonthsOf(int memberId) =>
      statuses[memberId]?.paidMonths ?? const {};

  FamilyPayment loading() => _with(load: FamilyStatusLoad.loading);

  FamilyPayment loaded(Map<int, PaymentPrecheck> statuses) =>
      _with(load: FamilyStatusLoad.loaded, statuses: statuses);

  FamilyPayment failed() => _with(load: FamilyStatusLoad.failed);

  FamilyPayment toggling(int memberId) {
    if (hasSettled(memberId)) return this;

    final next = {...excludedIds};
    if (!next.remove(memberId)) next.add(memberId);

    return _with(excludedIds: next);
  }

  FamilyPayment afterSubmit(
    FamilyPaymentOutcome outcome, {
    required int amountCents,
  }) {
    return _with(
      registered: {
        ...registered,
        ..._feesOf(outcome.registered, amountCents),
      },
      unconfirmed: {
        for (final MapEntry(:key, :value) in unconfirmed.entries)
          if (!outcome.registered.containsKey(key)) key: value,
        ...outcome.unconfirmed,
      },
    );
  }

  FamilyPayment confirmingLanded({required int amountCents}) {
    final landed = {
      for (final MapEntry(:key, :value) in unconfirmed.entries)
        if (paidMonthsOf(key).containsAll(value)) key: value,
    };
    if (landed.isEmpty) return this;

    return _with(
      registered: {...registered, ..._feesOf(landed, amountCents)},
      unconfirmed: {
        for (final MapEntry(:key, :value) in unconfirmed.entries)
          if (!landed.containsKey(key)) key: value,
      },
    );
  }

  static Map<int, RegisteredFee> _feesOf(
    Map<int, List<BillingMonth>> months,
    int amountCents,
  ) {
    return {
      for (final MapEntry(:key, :value) in months.entries)
        key: RegisteredFee(months: value, amountCents: amountCents),
    };
  }

  FamilyPayment _with({
    FamilyStatusLoad? load,
    Map<int, PaymentPrecheck>? statuses,
    Set<int>? excludedIds,
    Map<int, RegisteredFee>? registered,
    Map<int, List<BillingMonth>>? unconfirmed,
  }) {
    return FamilyPayment(
      load: load ?? this.load,
      statuses: statuses ?? this.statuses,
      excludedIds: excludedIds ?? this.excludedIds,
      registered: registered ?? this.registered,
      unconfirmed: unconfirmed ?? this.unconfirmed,
    );
  }

  @override
  List<Object?> get props =>
      [load, statuses, excludedIds, registered, unconfirmed];
}
