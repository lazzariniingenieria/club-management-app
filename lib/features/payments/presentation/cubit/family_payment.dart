import 'package:equatable/equatable.dart';

import '../../domain/entities/billing_month.dart';
import '../../domain/entities/payment_precheck.dart';

enum FamilyStatusLoad { loading, loaded, failed }

class FamilyPayment extends Equatable {
  final FamilyStatusLoad load;
  final Map<int, PaymentPrecheck> statuses;
  final Set<int> excludedIds;

  const FamilyPayment({
    this.load = FamilyStatusLoad.loading,
    this.statuses = const {},
    this.excludedIds = const {},
  });

  bool get isLoading => load == FamilyStatusLoad.loading;

  bool get isReady => load == FamilyStatusLoad.loaded;

  bool get failedToLoad => load == FamilyStatusLoad.failed;

  bool includes(int memberId) => !excludedIds.contains(memberId);

  Set<BillingMonth> paidMonthsOf(int memberId) =>
      statuses[memberId]?.paidMonths ?? const {};

  FamilyPayment loading() => _with(load: FamilyStatusLoad.loading);

  FamilyPayment loaded(Map<int, PaymentPrecheck> statuses) =>
      _with(load: FamilyStatusLoad.loaded, statuses: statuses);

  FamilyPayment failed() => _with(load: FamilyStatusLoad.failed);

  FamilyPayment toggling(int memberId) {
    final next = {...excludedIds};
    if (!next.remove(memberId)) next.add(memberId);

    return _with(excludedIds: next);
  }

  FamilyPayment _with({
    FamilyStatusLoad? load,
    Map<int, PaymentPrecheck>? statuses,
    Set<int>? excludedIds,
  }) {
    return FamilyPayment(
      load: load ?? this.load,
      statuses: statuses ?? this.statuses,
      excludedIds: excludedIds ?? this.excludedIds,
    );
  }

  @override
  List<Object?> get props => [load, statuses, excludedIds];
}
