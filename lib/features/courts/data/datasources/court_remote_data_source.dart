import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list_reader.dart';
import '../../../../core/network/api_writer.dart';
import '../../domain/entities/court_draft.dart';
import '../models/court_model.dart';

abstract class CourtRemoteDataSource {
  Future<List<CourtModel>> fetchCourts();

  Future<void> createCourt(CourtDraft draft);

  Future<void> updateCourt(int courtId, CourtDraft draft);

  Future<void> setCourtActive(int courtId, {required bool isActive});
}

class CourtRemoteDataSourceImpl implements CourtRemoteDataSource {
  CourtRemoteDataSourceImpl(ApiClient apiClient, AppLogger logger)
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

  static const String _logContext = 'CourtRemoteDataSource';

  @override
  Future<List<CourtModel>> fetchCourts() {
    return _reader.readLists(
      paths: const [ApiConstants.courts],
      build: (responses) => [
        for (final row in responses.single)
          CourtModel.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<void> createCourt(CourtDraft draft) {
    return _writer.post(ApiConstants.courts, CourtModel.bodyFromDraft(draft));
  }

  @override
  Future<void> updateCourt(int courtId, CourtDraft draft) {
    return _writer.patch(
      ApiConstants.court(courtId),
      body: CourtModel.bodyFromDraft(draft),
    );
  }

  @override
  Future<void> setCourtActive(int courtId, {required bool isActive}) {
    return _writer.patch(
      isActive
          ? ApiConstants.courtReactivation(courtId)
          : ApiConstants.courtDeactivation(courtId),
    );
  }
}
