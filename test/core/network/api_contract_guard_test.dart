import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/core/network/api_contract_guard.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingLogger implements AppLogger {
  final List<String> errors = [];

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
  }) =>
      errors.add('$context: $message');
}

void main() {
  late RecordingLogger logger;

  Future<T> guarded<T>(Future<T> Function() run) =>
      guardContract(run, logger: logger, logContext: 'Test');

  setUp(() => logger = RecordingLogger());

  test('hands back what the request returned', () async {
    expect(await guarded(() async => 42), 42);
    expect(logger.errors, isEmpty);
  });

  test('maps a failed request as every API call does', () {
    final request = RequestOptions(path: '/members/1');

    expect(
      guarded<void>(
        () => throw DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: 404),
          type: DioExceptionType.badResponse,
        ),
      ),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('a response off the contract is a logged server error', () async {
    await expectLater(
      guarded<int>(() async => ('not a number' as dynamic) as int),
      throwsA(isA<ServerException>()),
    );

    expect(
      logger.errors,
      ['Test: Response did not match the expected contract'],
    );
  });
}
