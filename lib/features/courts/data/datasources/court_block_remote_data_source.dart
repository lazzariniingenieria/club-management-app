import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list_reader.dart';
import '../../../../core/network/api_writer.dart';
import '../../domain/entities/court_block_draft.dart';
import '../models/court_block_model.dart';

abstract class CourtBlockRemoteDataSource {
  Future<List<CourtBlockModel>> fetchBlocks(
    int courtId, {
    required DateTime from,
  });

  Future<void> createBlock(int courtId, CourtBlockDraft draft);

  Future<void> removeBlock(int courtId, int blockId);
}

class CourtBlockRemoteDataSourceImpl implements CourtBlockRemoteDataSource {
  CourtBlockRemoteDataSourceImpl(ApiClient apiClient, AppLogger logger)
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

  static const String _logContext = 'CourtBlockRemoteDataSource';

  @override
  Future<List<CourtBlockModel>> fetchBlocks(
    int courtId, {
    required DateTime from,
  }) {
    final path = ApiConstants.courtBlocksFrom(
      courtId,
      CourtBlockModel.dayToJson(from),
    );

    return _reader.readLists(
      paths: [path],
      build: (responses) => [
        for (final row in responses.single)
          CourtBlockModel.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<void> createBlock(int courtId, CourtBlockDraft draft) {
    return _writer.post(
      ApiConstants.courtBlocks(courtId),
      CourtBlockModel.bodyFromDraft(draft),
    );
  }

  @override
  Future<void> removeBlock(int courtId, int blockId) {
    return _writer.delete(ApiConstants.courtBlock(courtId, blockId));
  }
}
