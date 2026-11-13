import 'dart:async';

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

  group('around a write', () {
    late Completer<ResponseBody> heldRead;
    late Completer<ResponseBody> heldWrite;

    Future<Response<List<dynamic>>> readMembers() =>
        apiClient.sharedGet<List<dynamic>>(ApiConstants.members);

    Future<void> writePayment() => apiClient.sendWrite(
          () => apiClient.dio.post<dynamic>(
            ApiConstants.payments,
            data: const <String, dynamic>{},
          ),
        );

    ResponseBody membersOfCall(int callCount) => jsonListResponse(200, [
          {'call': callCount},
        ]);

    setUp(() {
      heldRead = Completer<ResponseBody>();
      heldWrite = Completer<ResponseBody>();
      adapter = ScriptedHttpAdapter((options, callCount) {
        if (options.method == 'POST') return heldWrite.future;
        if (callCount == 1) return heldRead.future;

        return membersOfCall(callCount);
      });
      apiClient.dio.httpClientAdapter = adapter;
    });

    test('a read after a write never joins a request started before it',
        () async {
      final write = writePayment();
      final duringWrite = readMembers();
      heldWrite.complete(emptyResponse(201));
      await write;

      final afterWrite = readMembers();
      heldRead.complete(membersOfCall(1));

      expect((await afterWrite).data, [
        {'call': 2},
      ]);
      expect((await duringWrite).data, [
        {'call': 1},
      ]);
      expect(adapter.callsTo(ApiConstants.members), 2);
    });

    test('a read during a write never joins a request started before it',
        () async {
      final beforeWrite = readMembers();
      final write = writePayment();

      final duringWrite = readMembers();
      heldRead.complete(membersOfCall(1));

      expect((await duringWrite).data, [
        {'call': 2},
      ]);
      expect((await beforeWrite).data, [
        {'call': 1},
      ]);
      expect(adapter.callsTo(ApiConstants.members), 2);
      heldWrite.complete(emptyResponse(201));
      await write;
    });
  });
}
