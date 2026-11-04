import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../payments/domain/entities/billing_month.dart';
import '../../domain/entities/fee_receipts_document.dart';
import '../../domain/entities/payment_report_period.dart';

enum ReportStatus { editing, generating, ready, failed }

class PaymentReportState extends Equatable {
  static const int yearsOffered = 3;

  final PaymentReportPeriod? period;
  final BillingMonth currentMonth;
  final int visibleYear;
  final ReportStatus status;
  final FeeReceiptsDocument? document;
  final Failure? failure;
  final bool isDefaultSelection;

  const PaymentReportState({
    required this.period,
    required this.currentMonth,
    required this.visibleYear,
    this.status = ReportStatus.editing,
    this.document,
    this.failure,
    this.isDefaultSelection = false,
  });

  factory PaymentReportState.startingAt(BillingMonth currentMonth) =>
      PaymentReportState(
        period: PaymentReportPeriod.single(currentMonth),
        currentMonth: currentMonth,
        visibleYear: currentMonth.year,
        isDefaultSelection: true,
      );

  int get earliestYear => currentMonth.year - yearsOffered + 1;

  bool get isGenerating => status == ReportStatus.generating;

  bool get canGenerate => period != null && !isGenerating;

  bool get timedOut => failure is ResponseTimeoutFailure;

  bool get isOffline => failure is NetworkFailure;

  bool get hadNoCollections =>
      status == ReportStatus.ready && document == null;

  bool isOffered(BillingMonth month) =>
      !currentMonth.isBefore(month) && month.year >= earliestYear;

  bool includes(BillingMonth month) {
    final selected = period;

    return selected != null &&
        !month.isBefore(selected.from) &&
        !selected.to.isBefore(month);
  }

  bool canToggle(BillingMonth month) {
    if (!isOffered(month)) return false;

    final selected = period;
    if (selected == null || isDefaultSelection) return true;

    return !_isInTheMiddle(selected, month);
  }

  bool _isInTheMiddle(PaymentReportPeriod selected, BillingMonth month) =>
      includes(month) && month != selected.from && month != selected.to;

  PaymentReportState toggling(BillingMonth month) {
    if (!canToggle(month)) return this;

    return _editing(_toggled(month));
  }

  PaymentReportPeriod? _toggled(BillingMonth month) {
    final selected = period;
    if (selected == null) return PaymentReportPeriod.single(month);
    if (isDefaultSelection) return _replacingDefault(selected, month);
    if (month == selected.from) return _withoutFirst(selected);
    if (month == selected.to) return _withoutLast(selected);
    if (month == selected.from.previous) return _from(selected, month);
    if (month == selected.to.next) return _until(selected, month);

    return PaymentReportPeriod.single(month);
  }

  static PaymentReportPeriod? _replacingDefault(
    PaymentReportPeriod selected,
    BillingMonth month,
  ) =>
      month == selected.from ? null : PaymentReportPeriod.single(month);

  static PaymentReportPeriod? _withoutFirst(PaymentReportPeriod selected) =>
      selected.isSingleMonth
          ? null
          : PaymentReportPeriod(from: selected.from.next, to: selected.to);

  static PaymentReportPeriod _withoutLast(PaymentReportPeriod selected) =>
      PaymentReportPeriod(from: selected.from, to: selected.to.previous);

  static PaymentReportPeriod _from(
    PaymentReportPeriod selected,
    BillingMonth month,
  ) =>
      PaymentReportPeriod(from: month, to: selected.to);

  static PaymentReportPeriod _until(
    PaymentReportPeriod selected,
    BillingMonth month,
  ) =>
      PaymentReportPeriod(from: selected.from, to: month);

  PaymentReportState showingYear(int year) => PaymentReportState(
        period: period,
        currentMonth: currentMonth,
        visibleYear: year.clamp(earliestYear, currentMonth.year),
        status: status,
        document: document,
        failure: failure,
        isDefaultSelection: isDefaultSelection,
      );

  PaymentReportState withStatus(
    ReportStatus status, {
    FeeReceiptsDocument? document,
    Failure? failure,
  }) {
    return PaymentReportState(
      period: period,
      currentMonth: currentMonth,
      visibleYear: visibleYear,
      status: status,
      document: document,
      failure: failure,
      isDefaultSelection: isDefaultSelection,
    );
  }

  PaymentReportState _editing(PaymentReportPeriod? period) {
    return PaymentReportState(
      period: period,
      currentMonth: currentMonth,
      visibleYear: visibleYear,
    );
  }

  @override
  List<Object?> get props => [
        period,
        currentMonth,
        visibleYear,
        status,
        document,
        failure,
        isDefaultSelection,
      ];
}
