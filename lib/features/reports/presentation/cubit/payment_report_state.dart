import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../payments/domain/entities/billing_month.dart';
import '../../domain/entities/fee_receipts_document.dart';
import '../../domain/entities/payment_report_period.dart';

enum ReportRangeMode { single, range }

enum ReportStatus { editing, generating, ready, failed }

class PaymentReportState extends Equatable {
  final ReportRangeMode mode;
  final BillingMonth from;
  final BillingMonth to;
  final ReportStatus status;
  final FeeReceiptsDocument? document;
  final Failure? failure;
  final List<BillingMonth> offeredMonths;

  const PaymentReportState({
    required this.from,
    required this.to,
    required this.offeredMonths,
    this.mode = ReportRangeMode.single,
    this.status = ReportStatus.editing,
    this.document,
    this.failure,
  });

  PaymentReportPeriod get period => mode == ReportRangeMode.single
      ? PaymentReportPeriod.single(from)
      : PaymentReportPeriod(from: from, to: to);

  bool get isGenerating => status == ReportStatus.generating;

  bool get canGenerate => period.isValid && !isGenerating;

  bool get isOffline => failure is NetworkFailure;

  bool get hadNoCollections =>
      status == ReportStatus.ready && document == null;

  PaymentReportState editing({
    ReportRangeMode? mode,
    BillingMonth? from,
    BillingMonth? to,
  }) {
    return PaymentReportState(
      mode: mode ?? this.mode,
      from: from ?? this.from,
      to: to ?? this.to,
      offeredMonths: offeredMonths,
    );
  }

  PaymentReportState withStatus(
    ReportStatus status, {
    FeeReceiptsDocument? document,
    Failure? failure,
  }) {
    return PaymentReportState(
      mode: mode,
      from: from,
      to: to,
      offeredMonths: offeredMonths,
      status: status,
      document: document,
      failure: failure,
    );
  }

  @override
  List<Object?> get props =>
      [mode, from, to, offeredMonths, status, document, failure];
}
