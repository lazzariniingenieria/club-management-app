import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/core/network/api_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class SilentLogger implements AppLogger {
  const SilentLogger();

  @override
  void info(String message, {String? context}) {}

  @override
  void warning(String message, {String? context}) {}

  @override
  void error(
    String message, {
    String? context,
    Object? cause,
    StackTrace? stackTrace,
  }) {}
}

void main() {
  Exception mapped(DioExceptionType type) {
    return apiExceptionFrom(
      DioException(
        requestOptions: RequestOptions(path: '/payments'),
        type: type,
      ),
      logger: const SilentLogger(),
      logContext: 'test',
    );
  }

  test('a request sent without an answer may have landed: a timeout', () {
    expect(
      mapped(DioExceptionType.receiveTimeout),
      isA<ResponseTimeoutException>(),
    );
    expect(
      mapped(DioExceptionType.sendTimeout),
      isA<ResponseTimeoutException>(),
    );
  });

  test('a server that could not be reached never got the request', () {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
    ]) {
      final error = mapped(type);

      expect(error, isA<NetworkException>());
      expect(error, isNot(isA<ResponseTimeoutException>()));
    }
  });
}
