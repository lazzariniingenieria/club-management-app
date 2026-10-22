import 'dart:typed_data';

import 'package:club_management_app/core/constants/api_constants.dart';
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/core/network/api_client.dart';
import 'package:club_management_app/core/session/session_expiry_notifier.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/reports/data/datasources/payment_report_remote_data_source.dart';
import 'package:club_management_app/features/reports/domain/entities/payment_report_period.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_secure_storage.dart';
import '../../../helpers/scripted_http_adapter.dart';

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

ResponseBody pdfResponse(List<int> bytes, {String? disposition}) {
  return ResponseBody.fromBytes(
    bytes,
    200,
    headers: {
      Headers.contentTypeHeader: ['application/pdf'],
      if (disposition != null) 'content-disposition': [disposition],
    },
  );
}

void main() {
  late ScriptedHttpAdapter adapter;
  const october = PaymentReportPeriod.single(BillingMonth(2026, 10));

  PaymentReportRemoteDataSourceImpl buildDataSource(Responder responder) {
    final dio = Dio();
    final apiClient = ApiClient(
      dio: dio,
      refreshClient: Dio(),
      secureStorage: InMemorySecureStorage(),
      sessionExpiryNotifier: SessionExpiryNotifier(),
      logger: const SilentLogger(),
      baseUrl: 'https://api.test/api',
    );
    adapter = ScriptedHttpAdapter(responder);
    dio.httpClientAdapter = adapter;

    return PaymentReportRemoteDataSourceImpl(apiClient, const SilentLogger());
  }

  test('asks for the collection days of the period', () async {
    final source = buildDataSource((_, __) => pdfResponse([37, 80, 68, 70]));

    await source.fetchFeeReceipts(october);

    final request = adapter.requests.single;
    expect(request.path, ApiConstants.feeReceipts);
    expect(request.queryParameters, {
      'paidFrom': '2026-10-01',
      'paidTo': '2026-10-31',
    });
  });

  test('returns the PDF with the file name the backend chose', () async {
    final source = buildDataSource(
      (_, __) => pdfResponse(
        [37, 80, 68, 70],
        disposition:
            'attachment; filename="cuotas-cobradas-2026-10-01-al-2026-10-31.pdf"',
      ),
    );

    final document = await source.fetchFeeReceipts(october);

    expect(document!.bytes, Uint8List.fromList([37, 80, 68, 70]));
    expect(document.fileName, 'cuotas-cobradas-2026-10-01-al-2026-10-31.pdf');
  });

  test('a 204 means there were no collections, not an error', () async {
    final source = buildDataSource((_, __) => emptyResponse(204));

    expect(await source.fetchFeeReceipts(october), isNull);
  });

  test('a 400 is a rejected request', () {
    final source = buildDataSource((_, __) => jsonResponse(400));

    expect(
      () => source.fetchFeeReceipts(october),
      throwsA(isA<ValidationException>()),
    );
  });
}
