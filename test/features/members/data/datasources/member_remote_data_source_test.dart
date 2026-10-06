import 'package:club_management_app/core/constants/api_constants.dart';
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/core/network/api_client.dart';
import 'package:club_management_app/core/session/session_expiry_notifier.dart';
import 'package:club_management_app/features/members/data/datasources/member_remote_data_source.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
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

const List<dynamic> _members = [
  {
    'id': 1,
    'firstName': 'Juan',
    'lastName': 'Pérez',
    'dni': '30111222',
    'status': 'ACTIVE',
  },
  {
    'id': 2,
    'firstName': 'Luis',
    'lastName': 'Romero',
    'dni': '31444555',
    'status': 'INACTIVE',
  },
];

const List<dynamic> _delinquency = [
  {'memberId': 1, 'daysOverdue': 42},
];

void main() {
  late ScriptedHttpAdapter adapter;

  MemberRemoteDataSourceImpl buildDataSource(Responder responder) {
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

    return MemberRemoteDataSourceImpl(apiClient, const SilentLogger());
  }

  ResponseBody respondWithBothLists(RequestOptions options, int callCount) {
    return switch (options.path) {
      ApiConstants.members => jsonListResponse(200, _members),
      ApiConstants.paymentDelinquency => jsonListResponse(200, _delinquency),
      _ => emptyResponse(404),
    };
  }

  test('asks the API for the roster and the delinquency report', () async {
    final dataSource = buildDataSource(respondWithBothLists);

    await dataSource.fetchMembers();

    expect(adapter.callsTo(ApiConstants.members), 1);
    expect(adapter.callsTo(ApiConstants.paymentDelinquency), 1);
  });

  test('merges both responses into one roster', () async {
    final dataSource = buildDataSource(respondWithBothLists);

    final roster = await dataSource.fetchMembers();

    expect(roster, hasLength(2));
    expect(roster.first.fullName, 'Juan Pérez');
    expect(roster.first.daysOverdue, 42);
    expect(roster.last.status, MemberStatus.inactive);
    expect(roster.last.isOverdue, isFalse);
  });

  test('maps a connection failure to a network error', () {
    final dataSource = buildDataSource((options, _) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'host unreachable',
      );
    });

    expect(dataSource.fetchMembers(), throwsA(isA<NetworkException>()));
  });

  test('maps a 500 to a server error', () {
    final dataSource = buildDataSource((_, __) => jsonResponse(500));

    expect(dataSource.fetchMembers(), throwsA(isA<ServerException>()));
  });

  test('reports a contract drift instead of crashing on a TypeError', () {
    final dataSource = buildDataSource((options, _) {
      return switch (options.path) {
        ApiConstants.members => jsonListResponse(200, const [
            {'id': 1, 'firstName': 'Juan', 'lastName': null, 'dni': '1'},
          ]),
        _ => jsonListResponse(200, _delinquency),
      };
    });

    expect(dataSource.fetchMembers(), throwsA(isA<ServerException>()));
  });
}
