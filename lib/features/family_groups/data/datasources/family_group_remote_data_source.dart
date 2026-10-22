import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_contract_guard.dart';
import '../../../../core/network/api_list_reader.dart';
import '../../../../core/network/api_object_reader.dart';
import '../../../../core/network/api_writer.dart';
import '../models/family_group_model.dart';

abstract class FamilyGroupRemoteDataSource {
  Future<FamilyGroupModel> fetchGroup(int familyGroupId);

  Future<List<FamilyGroupModel>> fetchGroups();

  Future<FamilyGroupModel> createGroup({String? name});

  Future<void> renameGroup(int familyGroupId, String? name);
}

class FamilyGroupRemoteDataSourceImpl implements FamilyGroupRemoteDataSource {
  FamilyGroupRemoteDataSourceImpl(ApiClient apiClient, this._logger)
      : _reader = ApiObjectReader(
          apiClient: apiClient,
          logger: _logger,
          logContext: _logContext,
        ),
        _listReader = ApiListReader(
          apiClient: apiClient,
          logger: _logger,
          logContext: _logContext,
        ),
        _writer = ApiWriter(
          apiClient: apiClient,
          logger: _logger,
          logContext: _logContext,
        );

  final AppLogger _logger;
  final ApiObjectReader _reader;
  final ApiListReader _listReader;
  final ApiWriter _writer;

  static const String _logContext = 'FamilyGroupRemoteDataSource';

  @override
  Future<FamilyGroupModel> fetchGroup(int familyGroupId) {
    return _reader.readObject(
      path: ApiConstants.familyGroup(familyGroupId),
      build: FamilyGroupModel.fromJson,
    );
  }

  @override
  Future<List<FamilyGroupModel>> fetchGroups() {
    return _listReader.readLists(
      paths: const [ApiConstants.familyGroups],
      build: (responses) => [
        for (final row in responses.single)
          FamilyGroupModel.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<FamilyGroupModel> createGroup({String? name}) async {
    final created = await _writer.postForObject(
      ApiConstants.familyGroups,
      FamilyGroupModel.bodyWithName(name),
    );

    return guardContract(
      () async => FamilyGroupModel.fromJson(created),
      logger: _logger,
      logContext: _logContext,
    );
  }

  @override
  Future<void> renameGroup(int familyGroupId, String? name) {
    return _writer.patch(
      ApiConstants.familyGroup(familyGroupId),
      body: FamilyGroupModel.bodyWithName(name),
    );
  }
}
