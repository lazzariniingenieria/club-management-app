import 'package:dio/dio.dart';

import '../errors/exceptions.dart';
import '../logging/app_logger.dart';
import 'api_client.dart';

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
      throw _mapDioException(error);
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

  Exception _mapDioException(DioException error) {
    logger.error(
      '${error.requestOptions.path} failed with status '
      '${error.response?.statusCode}',
      context: logContext,
      cause: error,
    );

    if (_isConnectivityIssue(error)) {
      return NetworkException('Could not reach the server');
    }

    return ServerException(error.message ?? 'Unknown server error');
  }

  bool _isConnectivityIssue(DioException error) {
    return const {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    }.contains(error.type);
  }
}
