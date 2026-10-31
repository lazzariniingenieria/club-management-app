import 'package:club_management_app/core/constants/api_constants.dart';
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/core/network/api_client.dart';
import 'package:club_management_app/core/session/session_expiry_notifier.dart';
import 'package:club_management_app/features/admins/data/datasources/admin_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_secure_storage.dart';
import '../../../../helpers/scripted_http_adapter.dart';

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

  AdminRemoteDataSourceImpl buildDataSource(Responder responder) {
    final dio = Dio();
    final apiClient = ApiClient(
      dio: dio,
      refreshClient: Dio(),
      secureStorage: InMemorySecureStorage(),
      sessionExpiryNotifier: SessionExpiryNotifier(),
      logger: const SilentLogger(),
      baseUrl: 'https://api.test/api',
    );
    adapter = ScriptedHttpAdapter(responder);
    dio.httpClientAdapter = adapter;

    return AdminRemoteDataSourceImpl(apiClient, const SilentLogger());
  }

  group('changeOwnPassword', () {
    test('patches the signed-in account and accepts a 204', () async {
      final dataSource = buildDataSource((_, __) => emptyResponse(204));

      await dataSource.changeOwnPassword('nueva-clave-1');

      final sent = adapter.requests.single;
      expect(sent.method, 'PATCH');
      expect(sent.path, ApiConstants.ownPassword);
      expect(sent.data, {'newPassword': 'nueva-clave-1'});
    });

    test('never goes through the reset route of another admin', () async {
      final dataSource = buildDataSource((_, __) => emptyResponse(204));

      await dataSource.changeOwnPassword('nueva-clave-1');

      expect(adapter.requests.single.path, isNot(contains(ApiConstants.admins)));
    });

    test('a rejected password surfaces as a validation error', () async {
      final dataSource = buildDataSource((_, __) => jsonResponse(400));

      await expectLater(
        dataSource.changeOwnPassword('nueva-clave-1'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
