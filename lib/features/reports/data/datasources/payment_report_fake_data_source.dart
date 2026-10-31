import '../../../payments/domain/entities/billing_month.dart';
import '../../domain/entities/fee_receipts_document.dart';
import '../../domain/entities/payment_report_period.dart';
import '../models/fee_receipts_request.dart';
import 'payment_report_remote_data_source.dart';
import 'sample_pdf.dart';

class PaymentReportFakeDataSource implements PaymentReportRemoteDataSource {
  PaymentReportFakeDataSource({
    this.latency = const Duration(milliseconds: 600),
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final Duration latency;
  final DateTime Function() _clock;

  @override
  Future<FeeReceiptsDocument?> fetchFeeReceipts(
    PaymentReportPeriod period,
  ) async {
    await Future<void>.delayed(latency);
    if (BillingMonth.of(_clock()).isBefore(period.from)) return null;

    return FeeReceiptsDocument(
      bytes: SamplePdf.withText('Tabletas de cuotas cobradas (datos de prueba)'),
      fileName: FeeReceiptsRequest.defaultFileName(period),
    );
  }
}
