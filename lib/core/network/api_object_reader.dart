import '../logging/app_logger.dart';
import 'api_client.dart';
import 'api_contract_guard.dart';

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
  }) {
    return guardContract(
      () async {
        final response = await apiClient.dio.get<Map<String, dynamic>>(path);

        return build(response.data ?? const {});
      },
      logger: logger,
      logContext: logContext,
    );
  }
}
