import 'package:dio/dio.dart';

import '../errors/exceptions.dart';
import '../logging/app_logger.dart';

Exception apiExceptionFrom(
  DioException error, {
  required AppLogger logger,
  required String logContext,
}) {
  final statusCode = error.response?.statusCode;

  logger.error(
    '${error.requestOptions.path} failed with status $statusCode',
    context: logContext,
    cause: error,
  );

  if (_responseNeverArrived(error)) {
    return ResponseTimeoutException('The server did not answer in time');
  }
  if (_isConnectivityIssue(error)) {
    return NetworkException('Could not reach the server');
  }
  if (statusCode == 404) return NotFoundException('Resource not found');
  if (statusCode == 409) {
    return ConflictException('Conflicting data', _detailsOf(error.response));
  }
  if (statusCode == 400) return ValidationException('Request rejected');

  return ServerException(error.message ?? 'Unknown server error');
}

bool _responseNeverArrived(DioException error) {
  return const {
    DioExceptionType.receiveTimeout,
    DioExceptionType.sendTimeout,
  }.contains(error.type);
}

bool _isConnectivityIssue(DioException error) {
  return const {
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
  }.contains(error.type);
}

List<String> _detailsOf(Response<dynamic>? response) {
  final body = response?.data;
  if (body is! Map) return const [];

  final details = body['details'];
  if (details is! List) return const [];

  return [
    for (final detail in details)
      if (detail is String) detail,
  ];
}
