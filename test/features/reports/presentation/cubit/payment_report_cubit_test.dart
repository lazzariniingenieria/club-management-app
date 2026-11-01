import 'dart:async';
import 'dart:typed_data';

import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/reports/domain/entities/fee_receipts_document.dart';
import 'package:club_management_app/features/reports/domain/entities/payment_report_period.dart';
import 'package:club_management_app/features/reports/domain/usecases/download_fee_receipts_use_case.dart';
import 'package:club_management_app/features/reports/presentation/cubit/payment_report_cubit.dart';
import 'package:club_management_app/features/reports/presentation/cubit/payment_report_state.dart';
import 'package:club_management_app/features/reports/presentation/export/report_file_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDownloadReceipts extends Mock implements DownloadFeeReceiptsUseCase {}

class MockExporter extends Mock implements ReportFileExporter {}

class SilentLogger implements AppLogger {
  const SilentLogger();

  @override
  void info(String message, {String? context}) {}

  @override
  void warning(String message, {String? context}) {}

  @override
  void error(String message,
      {String? context, Object? cause, StackTrace? stackTrace}) {}
}

typedef Download = Either<Failure, FeeReceiptsDocument?>;

void main() {
  late MockDownloadReceipts download;
  late PaymentReportCubit cubit;

  const october = BillingMonth(2026, 10);
  const november = BillingMonth(2026, 11);
  final octoberPdf = FeeReceiptsDocument(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: 'cuotas-cobradas-octubre-2026.pdf',
  );

  setUpAll(() {
    registerFallbackValue(const PaymentReportPeriod.single(october));
  });

  setUp(() {
    download = MockDownloadReceipts();
    cubit = PaymentReportCubit(
      downloadReceipts: download,
      exporter: MockExporter(),
      logger: const SilentLogger(),
      clock: () => DateTime(2026, 10, 23),
    );
  });

  tearDown(() => cubit.close());

  test('a PDF for a period no longer selected is discarded', () async {
    final pending = Completer<Download>();
    when(() => download(any())).thenAnswer((_) => pending.future);

    final generating = cubit.generate();
    cubit.selectFrom(november);
    pending.complete(Right(octoberPdf));
    await generating;

    expect(cubit.state.status, ReportStatus.editing);
    expect(cubit.state.from, november);
    expect(cubit.state.document, isNull);
  });

  test('offers the 24 months ending at the clock, newest first', () {
    final offered = cubit.state.offeredMonths;

    expect(offered, hasLength(PaymentReportCubit.monthsOffered));
    expect(offered.first, october);
    expect(offered[1], const BillingMonth(2026, 9));
    expect(offered.last, const BillingMonth(2024, 11));
  });

  test('a slow server is told apart from being offline', () async {
    when(() => download(any()))
        .thenAnswer((_) async => const Left(ResponseTimeoutFailure()));

    await cubit.generate();

    expect(cubit.state.timedOut, isTrue);
  });

  test('the PDF of the period still selected is kept', () async {
    when(() => download(any())).thenAnswer((_) async => Right(octoberPdf));

    await cubit.generate();

    expect(cubit.state.status, ReportStatus.ready);
    expect(cubit.state.document, octoberPdf);
    verify(() => download(const PaymentReportPeriod.single(october))).called(1);
  });
}
