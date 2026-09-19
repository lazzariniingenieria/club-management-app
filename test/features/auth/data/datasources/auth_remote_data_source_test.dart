import 'package:club_management_app/core/constants/api_constants.dart';
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/core/network/api_client.dart';
import 'package:club_management_app/core/session/session_expiry_notifier.dart';
import 'package:club_management_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_secure_storage.dart';
import '../../../../helpers/scripted_http_adapter.dart';

class SilentLogger implements AppLogger {
  final List<String> errors = [];

  @override
  void info(String message, {String? context}) {}

  @override
  void warning(String message, {String? context}) {}

  @override
  void error(String message,
      {String? context, Object? cause, StackTrace? stackTrace}) {
    errors.add(message);
  }
}

const Map<String, dynamic> _contractResponse = {
  'accessToken': 'eyJhbGciOiJIUzI1NiJ9.payload.signature',
  'userAccountId': 12,
  'role': 'ADMIN',
  'memberId': 34,
};

const Map<String, dynamic> _errorEnvelope = {
  'timestamp': '2026-09-10T14:03:11.482Z',
  'status': 401,
  'error': 'Unauthorized',
  'message': 'Invalid dni or password',
  'details': <String>[],
};

void main() {
  late SilentLogger logger;

  AuthRemoteDataSourceImpl buildDataSource(Responder responder) {
    final dio = Dio();
    final refreshClient = Dio();
    final apiClient = ApiClient(
      dio: dio,
      refreshClient: refreshClient,
      secureStorage: InMemorySecureStorage(),
      sessionExpiryNotifier: SessionExpiryNotifier(),
      logger: logger,
      baseUrl: 'https://api.test/api',
    );
    final adapter = ScriptedHttpAdapter(responder);
    dio.httpClientAdapter = adapter;
    refreshClient.httpClientAdapter = adapter;

    return AuthRemoteDataSourceImpl(apiClient, logger, clubId: 7);
  }

  setUp(() => logger = SilentLogger());

  group('the outgoing request', () {
    test('sends clubId, dni and password to the login endpoint', () async {
      late RequestOptions sent;
      final dataSource = buildDataSource((options, _) {
        sent = options;
        return jsonResponse(200, _contractResponse);
      });

      await dataSource.login('30111222', 's3cr3t123');

      expect(sent.path, ApiConstants.login);
      expect(sent.method, 'POST');
      expect(sent.data, {
        'clubId': 7,
        'dni': '30111222',
        'password': 's3cr3t123',
      });
    });

    test('serializes clubId as a number, which the API requires', () async {
      late RequestOptions sent;
      final dataSource = buildDataSource((options, _) {
        sent = options;
        return jsonResponse(200, _contractResponse);
      });

      await dataSource.login('30111222', 's3cr3t123');

      expect((sent.data as Map<String, dynamic>)['clubId'], isA<int>());
    });
  });

  group('the incoming response', () {
    test('maps the flat contract body', () async {
      final dataSource =
          buildDataSource((_, __) => jsonResponse(200, _contractResponse));

      final response = await dataSource.login('30111222', 's3cr3t123');

      expect(response.accessToken, _contractResponse['accessToken']);
      expect(response.user.id, 12);
      expect(response.user.role, UserRole.admin);
      expect(response.user.memberId, 34);
    });

    test('accepts a null memberId', () async {
      final dataSource = buildDataSource(
        (_, __) => jsonResponse(200, {
          ..._contractResponse,
          'role': 'SUPER_ADMIN',
          'memberId': null,
        }),
      );

      final response = await dataSource.login('30111222', 's3cr3t123');

      expect(response.user.memberId, isNull);
      expect(response.user.role, UserRole.superAdmin);
    });

    test('reports a contract drift as ServerException, not a TypeError', () {
      final dataSource = buildDataSource(
        (_, __) => jsonResponse(200, const {'userAccountId': 12}),
      );

      expect(
        () => dataSource.login('30111222', 's3cr3t123'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('error mapping', () {
    test('maps the 401 envelope without leaking its English message', () async {
      final dataSource =
          buildDataSource((_, __) => jsonResponse(401, _errorEnvelope));

      await expectLater(
        dataSource.login('30111222', 'wrong'),
        throwsA(
          isA<UnauthorizedException>().having(
            (exception) => exception.message,
            'message',
            isNot(contains('Invalid dni or password')),
          ),
        ),
      );
    });

    test('maps a 401 with an empty body', () {
      final dataSource = buildDataSource((_, __) => emptyResponse(401));

      expect(
        () => dataSource.login('30111222', 'wrong'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('maps a 400 to a validation failure', () {
      final dataSource = buildDataSource(
        (_, __) => jsonResponse(400, const {
          'status': 400,
          'message': 'Validation failed',
          'details': ['dni: dni is required'],
        }),
      );

      expect(
        () => dataSource.login('', 's3cr3t123'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('maps a connection failure to a network error', () {
      final dataSource = buildDataSource((options, _) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'host unreachable',
        );
      });

      expect(
        () => dataSource.login('30111222', 's3cr3t123'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('maps a 500 to a server error', () {
      final dataSource = buildDataSource((_, __) => jsonResponse(500));

      expect(
        () => dataSource.login('30111222', 's3cr3t123'),
        throwsA(isA<ServerException>()),
      );
    });

    test('never logs the dni or the password', () async {
      final dataSource = buildDataSource((_, __) => jsonResponse(401));

      await expectLater(
        dataSource.login('30111222', 's3cr3t123'),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(logger.errors.join(), isNot(contains('30111222')));
      expect(logger.errors.join(), isNot(contains('s3cr3t123')));
    });
  });
}
