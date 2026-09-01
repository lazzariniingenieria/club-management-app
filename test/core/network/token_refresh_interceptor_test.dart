import 'package:club_management_app/core/constants/api_constants.dart';
import 'package:club_management_app/core/constants/storage_keys.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/core/network/api_client.dart';
import 'package:club_management_app/core/session/session_expiry_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_secure_storage.dart';
import '../../helpers/scripted_http_adapter.dart';

void main() {
  const protectedPath = '/members';

  late InMemorySecureStorage storage;
  late SessionExpiryNotifier expiryNotifier;
  late List<void> expiryEvents;
  late Dio dio;

  ScriptedHttpAdapter buildClient(Responder responder) {
    final adapter = ScriptedHttpAdapter(responder);
    dio = Dio()..httpClientAdapter = adapter;
    final refreshClient = Dio()..httpClientAdapter = adapter;

    ApiClient(
      dio: dio,
      refreshClient: refreshClient,
      secureStorage: storage,
      sessionExpiryNotifier: expiryNotifier,
      logger: const DeveloperLogger(),
      baseUrl: 'https://api.test/v1',
    );

    return adapter;
  }

  setUp(() {
    storage = InMemorySecureStorage();
    expiryNotifier = SessionExpiryNotifier();
    expiryEvents = [];
    expiryNotifier.onSessionExpired.listen(expiryEvents.add);
  });

  tearDown(() => expiryNotifier.dispose());

  Future<void> flushExpiryEvents() => Future<void>.delayed(Duration.zero);

  group('when the access token is rejected', () {
    ResponseBody refreshThenSucceed(RequestOptions options, int callCount) {
      if (options.path == ApiConstants.refresh) {
        return jsonResponse(200, {
          'accessToken': 'fresh-access-token',
          'refreshToken': 'rotated-refresh-token',
          'tokenType': 'Bearer',
          'expiresIn': 86400,
        });
      }
      return callCount == 1
          ? jsonResponse(401, {'message': 'expired'})
          : jsonResponse(200, {'ok': true});
    }

    setUp(() {
      storage.values[StorageKeys.accessToken] = 'stale-access-token';
      storage.values[StorageKeys.refreshToken] = 'valid-refresh-token';
    });

    test('refreshes once and replays the original request', () async {
      final adapter = buildClient(refreshThenSucceed);

      final response = await dio.get<Map<String, dynamic>>(protectedPath);

      expect(response.statusCode, 200);
      expect(adapter.callsTo(ApiConstants.refresh), 1);
      expect(adapter.callsTo(protectedPath), 2);
    });

    test('replays the request with the refreshed token', () async {
      final adapter = buildClient(refreshThenSucceed);

      await dio.get<Map<String, dynamic>>(protectedPath);

      final replay = adapter.requests.last;
      expect(
        replay.headers[ApiConstants.authorizationHeader],
        'Bearer fresh-access-token',
      );
    });

    test('stores a rotated refresh token', () async {
      buildClient(refreshThenSucceed);

      await dio.get<Map<String, dynamic>>(protectedPath);

      expect(storage.values[StorageKeys.accessToken], 'fresh-access-token');
      expect(
        storage.values[StorageKeys.refreshToken],
        'rotated-refresh-token',
      );
    });

    test('keeps the existing refresh token when the server does not rotate it',
        () async {
      buildClient((options, callCount) {
        if (options.path == ApiConstants.refresh) {
          return jsonResponse(200, {'accessToken': 'fresh-access-token'});
        }
        return callCount == 1 ? jsonResponse(401) : jsonResponse(200);
      });

      await dio.get<Map<String, dynamic>>(protectedPath);

      expect(
        storage.values[StorageKeys.refreshToken],
        'valid-refresh-token',
      );
    });

    test('does not report the session as expired', () async {
      buildClient(refreshThenSucceed);

      await dio.get<Map<String, dynamic>>(protectedPath);
      await flushExpiryEvents();

      expect(expiryEvents, isEmpty);
    });
  });

  group('when several requests are rejected at the same time', () {
    setUp(() {
      storage.values[StorageKeys.accessToken] = 'stale-access-token';
      storage.values[StorageKeys.refreshToken] = 'valid-refresh-token';
    });

    ResponseBody rejectStaleTokens(RequestOptions options, int callCount) {
      if (options.path == ApiConstants.refresh) {
        return jsonResponse(200, {'accessToken': 'fresh-access-token'});
      }
      final authorization =
          options.headers[ApiConstants.authorizationHeader] as String?;
      return authorization == 'Bearer fresh-access-token'
          ? jsonResponse(200, {'ok': true})
          : jsonResponse(401, {'message': 'expired'});
    }

    test('refreshes once for the whole burst', () async {
      final adapter = buildClient(rejectStaleTokens);

      final responses = await Future.wait([
        dio.get<Map<String, dynamic>>(protectedPath),
        dio.get<Map<String, dynamic>>('/payments'),
        dio.get<Map<String, dynamic>>('/courts'),
      ]);

      expect(responses.map((response) => response.statusCode), everyElement(200));
      expect(adapter.callsTo(ApiConstants.refresh), 1);
    });

    test('replays every queued request with the token the first one obtained',
        () async {
      final adapter = buildClient(rejectStaleTokens);

      await Future.wait([
        dio.get<Map<String, dynamic>>(protectedPath),
        dio.get<Map<String, dynamic>>('/payments'),
        dio.get<Map<String, dynamic>>('/courts'),
      ]);

      final replays = adapter.requests
          .where((request) => request.extra['token_refresh_retried'] == true);

      expect(replays, hasLength(3));
      expect(
        replays.map(
            (request) => request.headers[ApiConstants.authorizationHeader]),
        everyElement('Bearer fresh-access-token'),
      );
    });
  });

  group('when the refresh token is also rejected', () {
    setUp(() {
      storage.values[StorageKeys.accessToken] = 'stale-access-token';
      storage.values[StorageKeys.refreshToken] = 'revoked-refresh-token';
    });

    ResponseBody alwaysUnauthorized(RequestOptions options, int callCount) =>
        jsonResponse(401, {'message': 'unauthorized'});

    test('surfaces the original error instead of looping', () async {
      final adapter = buildClient(alwaysUnauthorized);

      await expectLater(
        dio.get<Map<String, dynamic>>(protectedPath),
        throwsA(isA<DioException>()),
      );

      expect(adapter.callsTo(ApiConstants.refresh), 1);
      expect(adapter.callsTo(protectedPath), 1);
    });

    test('clears the stored session and reports it as expired', () async {
      buildClient(alwaysUnauthorized);

      await dio
          .get<Map<String, dynamic>>(protectedPath)
          .catchError((Object _) => Response<Map<String, dynamic>>(
                requestOptions: RequestOptions(path: protectedPath),
              ));
      await flushExpiryEvents();

      expect(storage.values, isEmpty);
      expect(expiryEvents, hasLength(1));
    });
  });

  group('when there is no refresh token stored', () {
    test('reports the session as expired without calling refresh', () async {
      storage.values[StorageKeys.accessToken] = 'stale-access-token';
      final adapter = buildClient((options, callCount) => jsonResponse(401));

      await dio
          .get<Map<String, dynamic>>(protectedPath)
          .catchError((Object _) => Response<Map<String, dynamic>>(
                requestOptions: RequestOptions(path: protectedPath),
              ));
      await flushExpiryEvents();

      expect(adapter.callsTo(ApiConstants.refresh), 0);
      expect(expiryEvents, hasLength(1));
    });
  });

  group('for errors that refreshing cannot fix', () {
    test('a 403 is passed through untouched', () async {
      storage.values[StorageKeys.refreshToken] = 'valid-refresh-token';
      final adapter = buildClient((options, callCount) => jsonResponse(403));

      await expectLater(
        dio.get<Map<String, dynamic>>(protectedPath),
        throwsA(isA<DioException>()),
      );
      await flushExpiryEvents();

      expect(adapter.callsTo(ApiConstants.refresh), 0);
      expect(expiryEvents, isEmpty);
    });
  });
}
