import 'package:dio/dio.dart';

import '../errors/exceptions.dart';
import '../logging/app_logger.dart';
import 'api_client.dart';
import 'api_error_mapper.dart';

class ApiListReader {
  final ApiClient apiClient;
  final AppLogger logger;
  final String logContext;

  ApiListReader({
    required this.apiClient,
    required this.logger,
    required this.logContext,
  });

  Future<T> readLists<T>({
    required List<String> paths,
    required T Function(List<List<dynamic>> responses) build,
  }) async {
    try {
      return build(await Future.wait(paths.map(_fetchList)));
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

  Future<List<dynamic>> _fetchList(String path) async {
    final response = await apiClient.dio.get<List<dynamic>>(path);

    return response.data ?? const [];
  }
}
