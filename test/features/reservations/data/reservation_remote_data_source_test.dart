import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/core/network/api_client.dart';
import 'package:club_management_app/core/session/session_expiry_notifier.dart';
import 'package:club_management_app/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_secure_storage.dart';
import '../../../helpers/scripted_http_adapter.dart';

class RecordingLogger implements AppLogger {
  final List<String> warnings = [];

  @override
  void info(String message, {String? context}) {}

  @override
  void warning(String message, {String? context}) => warnings.add(message);

  @override
  void error(String message,
      {String? context, Object? cause, StackTrace? stackTrace}) {}
}

Map<String, dynamic> reservationJson(int id, String? source) => {
      'id': id,
      'courtId': 1,
      'memberId': 7,
      if (source != null) 'source': source,
      'date': '2026-12-02',
      'startTime': '18:00',
      'endTime': '19:00',
    };

void main() {
  late RecordingLogger logger;

  ReservationRemoteDataSourceImpl dataSourceAnswering(List<dynamic> rows) {
    final dio = Dio();
    final apiClient = ApiClient(
      dio: dio,
      refreshClient: Dio(),
      secureStorage: InMemorySecureStorage(),
      sessionExpiryNotifier: SessionExpiryNotifier(),
      logger: RecordingLogger(),
      baseUrl: 'https://api.test/api',
    );
    dio.httpClientAdapter =
        ScriptedHttpAdapter((_, __) => jsonListResponse(200, rows));

    return ReservationRemoteDataSourceImpl(apiClient, logger);
  }

  setUp(() => logger = RecordingLogger());

  test('an unknown source is logged and read as a one-off reservation',
      () async {
    final dataSource = dataSourceAnswering([reservationJson(9, 'TOURNAMENT')]);

    final reservations =
        await dataSource.fetchReservations(DateTime(2026, 12, 2));

    expect(reservations.single.source, ReservationSource.member);
    expect(logger.warnings, hasLength(1));
    expect(logger.warnings.single, contains('TOURNAMENT'));
    expect(logger.warnings.single, contains('9'));
  });

  test('known or missing sources are read without warnings', () async {
    final dataSource = dataSourceAnswering([
      reservationJson(1, null),
      reservationJson(2, 'MEMBER'),
      reservationJson(3, 'RECURRING'),
      reservationJson(4, 'ACTIVITY'),
    ]);

    final reservations =
        await dataSource.fetchReservations(DateTime(2026, 12, 2));

    expect(
      [for (final reservation in reservations) reservation.source],
      [
        ReservationSource.member,
        ReservationSource.member,
        ReservationSource.recurring,
        ReservationSource.activity,
      ],
    );
    expect(logger.warnings, isEmpty);
  });
}
