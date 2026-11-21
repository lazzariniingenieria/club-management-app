import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/core/network/api_client.dart';
import 'package:club_management_app/core/session/session_expiry_notifier.dart';
import 'package:club_management_app/features/member_accounts/data/datasources/member_account_remote_data_source.dart';
import 'package:club_management_app/features/member_accounts/domain/entities/member_account.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_secure_storage.dart';
import '../../../helpers/scripted_http_adapter.dart';
import '../../../helpers/member_account_builders.dart';

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

  MemberAccountRemoteDataSourceImpl buildDataSource(Responder responder) {
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

    return MemberAccountRemoteDataSourceImpl(apiClient, const SilentLogger());
  }

  group('fetchAccount', () {
    test('reads the account of the member', () async {
      final dataSource =
          buildDataSource((_, __) => jsonResponse(200, memberAccountJson()));

      final account = await dataSource.fetchAccount(34);

      expect(account?.dni, '30111222');
      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.path, '/members/34/account');
    });

    test('a 204 without a content type means the member has no account',
        () async {
      final dataSource =
          buildDataSource((_, __) => ResponseBody.fromString('', 204));

      expect(await dataSource.fetchAccount(34), isNull);
    });

    test('a 204 announced as json also means no account', () async {
      final dataSource = buildDataSource((_, __) => emptyResponse(204));

      expect(await dataSource.fetchAccount(34), isNull);
    });

    test('a member outside the club is not found', () async {
      final dataSource = buildDataSource((_, __) => jsonResponse(404));

      await expectLater(
        dataSource.fetchAccount(34),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('a 200 without the account breaks the contract', () async {
      final dataSource = buildDataSource((_, __) => emptyResponse(200));

      await expectLater(
        dataSource.fetchAccount(34),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('createAccount', () {
    test('posts the initial password and reads the new account', () async {
      final dataSource =
          buildDataSource((_, __) => jsonResponse(201, memberAccountJson()));

      final account = await dataSource.createAccount(34, 's3cr3t123');

      final sent = adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.path, '/members/34/account');
      expect(sent.data, {'password': 's3cr3t123'});
      expect(account.role, MemberAccountRole.member);
    });

    test('a 409 surfaces as a conflict', () async {
      final dataSource = buildDataSource((_, __) => jsonResponse(409));

      await expectLater(
        dataSource.createAccount(34, 's3cr3t123'),
        throwsA(isA<ConflictException>()),
      );
    });

    test('a 400 surfaces as a validation error', () async {
      final dataSource = buildDataSource((_, __) => jsonResponse(400));

      await expectLater(
        dataSource.createAccount(34, 's3cr3t123'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('resetPassword', () {
    test('patches the new password of the member account', () async {
      final dataSource =
          buildDataSource((_, __) => jsonResponse(200, memberAccountJson()));

      await dataSource.resetPassword(34, 'n3wS3cr3t');

      final sent = adapter.requests.single;
      expect(sent.method, 'PATCH');
      expect(sent.path, '/members/34/account/password');
      expect(sent.data, {'newPassword': 'n3wS3cr3t'});
    });

    test('a member without a member account is not found', () async {
      final dataSource = buildDataSource((_, __) => jsonResponse(404));

      await expectLater(
        dataSource.resetPassword(34, 'n3wS3cr3t'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
