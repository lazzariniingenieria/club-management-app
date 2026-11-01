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

  const PaymentReportState({
    required this.period,
    required this.currentMonth,
    required this.visibleYear,
    this.status = ReportStatus.editing,
    this.document,
    this.failure,
  });

  factory PaymentReportState.startingAt(BillingMonth currentMonth) =>
      PaymentReportState(
        period: PaymentReportPeriod.single(currentMonth),
        currentMonth: currentMonth,
        visibleYear: currentMonth.year,
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
    if (selected == null) return true;

    return month == selected.from ||
        month == selected.to ||
        month == selected.from.previous ||
        month == selected.to.next;
  }

  PaymentReportState toggling(BillingMonth month) {
    if (!canToggle(month)) return this;

    return _editing(_toggled(period, month));
  }

  static PaymentReportPeriod? _toggled(
    PaymentReportPeriod? selected,
    BillingMonth month,
  ) {
    if (selected == null) return PaymentReportPeriod.single(month);
    if (selected.isSingleMonth && month == selected.from) return null;
    if (month == selected.from) {
      return PaymentReportPeriod(from: month.next, to: selected.to);
    }
    if (month == selected.to) {
      return PaymentReportPeriod(from: selected.from, to: month.previous);
    }

    return month.isBefore(selected.from)
        ? PaymentReportPeriod(from: month, to: selected.to)
        : PaymentReportPeriod(from: selected.from, to: month);
  }

  PaymentReportState showingYear(int year) => PaymentReportState(
        period: period,
        currentMonth: currentMonth,
        visibleYear: year.clamp(earliestYear, currentMonth.year),
        status: status,
        document: document,
        failure: failure,
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
  List<Object?> get props =>
      [period, currentMonth, visibleYear, status, document, failure];
}
