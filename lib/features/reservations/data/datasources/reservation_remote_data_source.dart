import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list_reader.dart';
import '../../../../core/network/api_writer.dart';
import '../../../courts/data/models/court_block_model.dart';
import '../../domain/entities/reservation_draft.dart';
import '../models/reservation_model.dart';

abstract class ReservationRemoteDataSource {
  Future<List<ReservationModel>> fetchReservations(DateTime day);

  Future<void> createReservation(ReservationDraft draft);

  Future<void> cancelReservation(int reservationId);
}

class ReservationRemoteDataSourceImpl implements ReservationRemoteDataSource {
  ReservationRemoteDataSourceImpl(ApiClient apiClient, AppLogger logger)
      : _reader = ApiListReader(
          apiClient: apiClient,
          logger: logger,
          logContext: _logContext,
        ),
        _writer = ApiWriter(
          apiClient: apiClient,
          logger: logger,
          logContext: _logContext,
        );

  final ApiListReader _reader;
  final ApiWriter _writer;

  static const String _logContext = 'ReservationRemoteDataSource';

  @override
  Future<List<ReservationModel>> fetchReservations(DateTime day) {
    return _reader.readLists(
      paths: [ApiConstants.reservationsOf(CourtBlockModel.dayToJson(day))],
      build: (responses) => [
        for (final row in responses.single)
          ReservationModel.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<void> createReservation(ReservationDraft draft) {
    return _writer.post(
      ApiConstants.reservations,
      ReservationModel.bodyFromDraft(draft),
    );
  }

  @override
  Future<void> cancelReservation(int reservationId) {
    return _writer.patch(ApiConstants.reservationCancellation(reservationId));
  }
}
