import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../payments/domain/entities/billing_month.dart';
import '../../domain/entities/fee_receipts_document.dart';
import '../../domain/entities/payment_report_period.dart';

enum ReportStatus { editing, generating, ready, failed }

class PaymentReportState extends Equatable {
  static const int yearsOffered = 3;

  final PaymentReportPeriod period;
  final BillingMonth currentMonth;
  final int visibleYear;
  final bool awaitsRangeEnd;
  final ReportStatus status;
  final FeeReceiptsDocument? document;
  final Failure? failure;

  const PaymentReportState({
    required this.period,
    required this.currentMonth,
    required this.visibleYear,
    this.awaitsRangeEnd = false,
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

  bool get canGenerate => period.isValid && !isGenerating;

  bool get timedOut => failure is ResponseTimeoutFailure;

  bool get isOffline => failure is NetworkFailure;

  bool get hadNoCollections =>
      status == ReportStatus.ready && document == null;

  bool isOffered(BillingMonth month) =>
      !currentMonth.isBefore(month) && month.year >= earliestYear;

  bool includes(BillingMonth month) =>
      !month.isBefore(period.from) && !period.to.isBefore(month);

  PaymentReportState tapping(BillingMonth month) {
    if (!awaitsRangeEnd || month == period.from) {
      return _editing(PaymentReportPeriod.single(month), awaitsRangeEnd: true);
    }

    final from = month.isBefore(period.from) ? month : period.from;
    final to = month.isBefore(period.from) ? period.from : month;

    return _editing(PaymentReportPeriod(from: from, to: to));
  }

  PaymentReportState showingYear(int year) => PaymentReportState(
        period: period,
        currentMonth: currentMonth,
        visibleYear: year.clamp(earliestYear, currentMonth.year),
        awaitsRangeEnd: awaitsRangeEnd,
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
      awaitsRangeEnd: awaitsRangeEnd,
      status: status,
      document: document,
      failure: failure,
    );
  }

  PaymentReportState _editing(
    PaymentReportPeriod period, {
    bool awaitsRangeEnd = false,
  }) {
    return PaymentReportState(
      period: period,
      currentMonth: currentMonth,
      visibleYear: visibleYear,
      awaitsRangeEnd: awaitsRangeEnd,
    );
  }

  @override
  List<Object?> get props => [
        period,
        currentMonth,
        visibleYear,
        awaitsRangeEnd,
        status,
        document,
        failure,
      ];
}
