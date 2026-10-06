import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list_reader.dart';
import '../models/member_model.dart';

abstract class MemberRemoteDataSource {
  Future<List<MemberModel>> fetchMembers();
}

class MemberRemoteDataSourceImpl implements MemberRemoteDataSource {
  MemberRemoteDataSourceImpl(ApiClient apiClient, AppLogger logger)
      : _reader = ApiListReader(
          apiClient: apiClient,
          logger: logger,
          logContext: 'MemberRemoteDataSource',
        );

  final ApiListReader _reader;

  @override
  Future<List<MemberModel>> fetchMembers() {
    return _reader.readLists(
      paths: const [ApiConstants.members, ApiConstants.paymentDelinquency],
      build: (responses) => MemberModel.listFromResponses(
        members: responses.first,
        delinquency: responses.last,
      ),
    );
  }
}
