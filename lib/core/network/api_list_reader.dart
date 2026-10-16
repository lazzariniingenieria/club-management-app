import '../logging/app_logger.dart';
import 'api_client.dart';
import 'api_contract_guard.dart';

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
  }) {
    return guardContract(
      () async => build(await Future.wait(paths.map(_fetchList))),
      logger: logger,
      logContext: logContext,
    );
  }

  Future<List<dynamic>> _fetchList(String path) async {
    final response = await apiClient.dio.get<List<dynamic>>(path);

    return response.data ?? const [];
  }
}
