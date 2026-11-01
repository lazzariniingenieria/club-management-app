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

  const june = BillingMonth(2026, 6);
  const august = BillingMonth(2026, 8);
  const september = BillingMonth(2026, 9);
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
    cubit.tapMonth(september);
    pending.complete(Right(octoberPdf));
    await generating;

    expect(cubit.state.status, ReportStatus.editing);
    expect(
      cubit.state.period,
      const PaymentReportPeriod(from: september, to: october),
    );
    expect(cubit.state.document, isNull);
  });

  group('choosing the months one by one, always in a row', () {
    test('opens on the current month alone', () {
      expect(cubit.state.period, const PaymentReportPeriod.single(october));
    });

    test('a neighbouring month joins the selection', () {
      cubit
        ..tapMonth(september)
        ..tapMonth(august);

      expect(
        cubit.state.period,
        const PaymentReportPeriod(from: august, to: october),
      );
    });

    test('a month at either end leaves it', () {
      cubit
        ..tapMonth(september)
        ..tapMonth(august)
        ..tapMonth(august)
        ..tapMonth(october);

      expect(cubit.state.period, const PaymentReportPeriod.single(september));
    });

    test('a month in the middle stays, so the period has no gap', () {
      cubit
        ..tapMonth(september)
        ..tapMonth(august)
        ..tapMonth(september);

      expect(cubit.state.canToggle(september), isFalse);
      expect(
        cubit.state.period,
        const PaymentReportPeriod(from: august, to: october),
      );
    });

    test('a month away from the selection cannot join it', () {
      cubit.tapMonth(june);

      expect(cubit.state.canToggle(june), isFalse);
      expect(cubit.state.period, const PaymentReportPeriod.single(october));
    });

    test('unticking the only month leaves nothing to generate', () {
      cubit.tapMonth(october);

      expect(cubit.state.period, isNull);
      expect(cubit.state.canGenerate, isFalse);

      cubit.tapMonth(june);
      expect(cubit.state.period, const PaymentReportPeriod.single(june));
    });

    test('a month that has not started cannot be picked', () {
      cubit.tapMonth(november);

      expect(cubit.state.period, const PaymentReportPeriod.single(october));
    });

    test('the years go back three and never past the current one', () {
      cubit.showYear(2030);
      expect(cubit.state.visibleYear, 2026);

      cubit.showYear(2020);
      expect(cubit.state.visibleYear, 2024);
    });
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
