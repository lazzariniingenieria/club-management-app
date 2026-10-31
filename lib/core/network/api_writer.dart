import 'package:dio/dio.dart';

import '../logging/app_logger.dart';
import 'api_client.dart';
import 'api_contract_guard.dart';
import 'api_error_mapper.dart';

class ApiWriter {
  final ApiClient apiClient;
  final AppLogger logger;
  final String logContext;

  ApiWriter({
    required this.apiClient,
    required this.logger,
    required this.logContext,
  });

  Future<void> post(String path, Map<String, dynamic> body) {
    return _send(() => apiClient.dio.post<dynamic>(path, data: body));
  }

  Future<void> patch(String path, {Map<String, dynamic>? body}) {
    return _send(() => apiClient.dio.patch<dynamic>(path, data: body));
  }

  Future<void> delete(String path) {
    return _send(() => apiClient.dio.delete<dynamic>(path));
  }

  Future<Map<String, dynamic>> postForObject(
    String path,
    Map<String, dynamic> body,
  ) {
    return guardContract(
      () async {
        final response =
            await apiClient.dio.post<Map<String, dynamic>>(path, data: body);

        return response.data ?? const {};
      },
      logger: logger,
      logContext: logContext,
    );
  }

  Future<void> _send(Future<Response<dynamic>> Function() request) async {
    try {
      await request();
    } on DioException catch (error) {
      throw apiExceptionFrom(error, logger: logger, logContext: logContext);
    }
  }
}
