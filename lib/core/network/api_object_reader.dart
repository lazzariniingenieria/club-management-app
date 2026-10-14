import 'package:dio/dio.dart';

import '../errors/exceptions.dart';
import '../logging/app_logger.dart';
import 'api_client.dart';
import 'api_error_mapper.dart';

class ApiObjectReader {
  final ApiClient apiClient;
  final AppLogger logger;
  final String logContext;

  ApiObjectReader({
    required this.apiClient,
    required this.logger,
    required this.logContext,
  });

  Future<T> readObject<T>({
    required String path,
    required T Function(Map<String, dynamic> response) build,
  }) async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(path);

      return build(response.data ?? const {});
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
}
