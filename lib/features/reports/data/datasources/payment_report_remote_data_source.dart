import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/fee_receipts_document.dart';
import '../../domain/entities/payment_report_period.dart';
import '../models/fee_receipts_request.dart';

abstract class PaymentReportRemoteDataSource {
  Future<FeeReceiptsDocument?> fetchFeeReceipts(PaymentReportPeriod period);
}

class PaymentReportRemoteDataSourceImpl
    implements PaymentReportRemoteDataSource {
  PaymentReportRemoteDataSourceImpl(this._apiClient, this._logger);

  final ApiClient _apiClient;
  final AppLogger _logger;

  static const String _logContext = 'PaymentReportRemoteDataSource';

  @override
  Future<FeeReceiptsDocument?> fetchFeeReceipts(
    PaymentReportPeriod period,
  ) async {
    try {
      final response = await _apiClient.dio.get<List<int>>(
        ApiConstants.feeReceipts,
        queryParameters: FeeReceiptsRequest.queryOf(period),
        options: Options(
          responseType: ResponseType.bytes,
          headers: {ApiConstants.acceptHeader: ApiConstants.pdfMediaType},
          receiveTimeout: ApiConstants.reportReceiveTimeout,
        ),
      );

      return _documentFrom(response, period);
    } on DioException catch (error) {
      throw apiExceptionFrom(error, logger: _logger, logContext: _logContext);
    }
  }

  static FeeReceiptsDocument? _documentFrom(
    Response<List<int>> response,
    PaymentReportPeriod period,
  ) {
    final bytes = response.data;
    if (response.statusCode == 204 || bytes == null || bytes.isEmpty) {
      return null;
    }

    return FeeReceiptsDocument(
      bytes: Uint8List.fromList(bytes),
      fileName: FeeReceiptsRequest.fileNameFrom(
            response.headers.value('content-disposition'),
          ) ??
          FeeReceiptsRequest.defaultFileName(period),
    );
  }
}
