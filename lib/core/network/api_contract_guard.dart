import 'package:dio/dio.dart';

import '../errors/exceptions.dart';
import '../logging/app_logger.dart';
import 'api_error_mapper.dart';

Future<T> guardContract<T>(
  Future<T> Function() run, {
  required AppLogger logger,
  required String logContext,
}) async {
  try {
    return await run();
  } on DioException catch (error) {
    throw apiExceptionFrom(error, logger: logger, logContext: logContext);
  } on TypeError catch (error) {
    logger.error(
      'Response did not match the expected contract',
      context: logContext,
      cause: error,
    );

    throw ServerException('Response did not match the contract');
  }
}
