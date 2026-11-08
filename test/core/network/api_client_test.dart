import 'package:club_management_app/core/constants/api_constants.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/core/network/api_client.dart';
import 'package:club_management_app/core/session/session_expiry_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_secure_storage.dart';
import '../../helpers/scripted_http_adapter.dart';

class SilentLogger implements AppLogger {
  const SilentLogger();

  @override
  void info(String message, {String? context}) {}

  @override
  void warning(String message, {String? context}) {}

  @override
  void error(String message,
      {String? context, Object? cause, StackTrace? stackTrace}) {}
}

void main() {
  late ScriptedHttpAdapter adapter;
  late ApiClient apiClient;

  setUp(() {
    final dio = Dio();
    apiClient = ApiClient(
      dio: dio,
      refreshClient: Dio(),
      secureStorage: InMemorySecureStorage(),
      sessionExpiryNotifier: SessionExpiryNotifier(),
      logger: const SilentLogger(),
      baseUrl: 'https://api.test/api',
    );
    adapter = ScriptedHttpAdapter(
      (options, callCount) => jsonListResponse(200, [
        {'call': callCount},
      ]),
    );
    dio.httpClientAdapter = adapter;
  });

  test('screens loading the same list at once share one request', () async {
    final responses = await Future.wait([
      apiClient.sharedGet<List<dynamic>>(ApiConstants.members),
      apiClient.sharedGet<List<dynamic>>(ApiConstants.members),
      apiClient.sharedGet<List<dynamic>>(ApiConstants.members),
    ]);

    expect(adapter.callsTo(ApiConstants.members), 1);
    for (final response in responses) {
      expect(response.data, [
        {'call': 1},
      ]);
    }
  });

  test('a list loaded after the previous one finished is asked again',
      () async {
    await apiClient.sharedGet<List<dynamic>>(ApiConstants.members);
    final second =
        await apiClient.sharedGet<List<dynamic>>(ApiConstants.members);

    expect(adapter.callsTo(ApiConstants.members), 2);
    expect(second.data, [
      {'call': 2},
    ]);
  });
}
