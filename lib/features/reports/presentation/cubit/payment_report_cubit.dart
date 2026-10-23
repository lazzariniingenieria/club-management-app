import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../payments/domain/entities/billing_month.dart';
import '../../domain/entities/payment_report_period.dart';
import '../../domain/usecases/download_fee_receipts_use_case.dart';
import '../export/report_file_exporter.dart';
import 'payment_report_state.dart';

class PaymentReportCubit extends Cubit<PaymentReportState> {
  final DownloadFeeReceiptsUseCase _downloadReceipts;
  final ReportFileExporter _exporter;
  final AppLogger _logger;

  PaymentReportCubit({
    required DownloadFeeReceiptsUseCase downloadReceipts,
    required ReportFileExporter exporter,
    required AppLogger logger,
    DateTime Function() clock = DateTime.now,
  })  : _downloadReceipts = downloadReceipts,
        _exporter = exporter,
        _logger = logger,
        super(
          PaymentReportState(
            from: BillingMonth.of(clock()),
            to: BillingMonth.of(clock()),
          ),
        );

  void selectMode(ReportRangeMode mode) => emit(state.editing(mode: mode));

  void selectFrom(BillingMonth month) => emit(state.editing(from: month));

  void selectTo(BillingMonth month) => emit(state.editing(to: month));

  Future<void> generate() async {
    if (!state.canGenerate) return;
    final requested = state.period;
    emit(state.withStatus(ReportStatus.generating));

    final result = await _downloadReceipts(requested);
    if (isClosed || !_isStillWaitingFor(requested)) return;

    emit(
      result.fold(
        (failure) => state.withStatus(ReportStatus.failed, failure: failure),
        (document) => state.withStatus(ReportStatus.ready, document: document),
      ),
    );
  }

  bool _isStillWaitingFor(PaymentReportPeriod requested) =>
      state.status == ReportStatus.generating && state.period == requested;

  Future<bool> share() => _export(_exporter.share);

  Future<bool> preview() => _export(_exporter.preview);

  Future<bool> _export(
    Future<void> Function(Uint8List bytes, String name) action,
  ) async {
    final document = state.document;
    if (document == null) return false;

    try {
      await action(document.bytes, document.fileName);

      return true;
    } catch (error) {
      _logger.error(
        'Exporting the fee receipts failed',
        context: 'PaymentReportCubit',
        cause: error,
      );

      return false;
    }
  }
}
