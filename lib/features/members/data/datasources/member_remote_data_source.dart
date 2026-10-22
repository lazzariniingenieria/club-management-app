import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list_reader.dart';
import '../../../../core/network/api_writer.dart';
import '../../domain/entities/member_draft.dart';
import '../models/member_model.dart';

abstract class MemberRemoteDataSource {
  Future<List<MemberModel>> fetchMembers();

  Future<void> createMember(MemberDraft draft);

  Future<void> updateMember(int memberId, MemberDraft draft);

  Future<void> setMemberActive(int memberId, {required bool isActive});

  Future<void> assignFamilyGroup(int memberId, int familyGroupId);

  Future<void> removeFromFamilyGroup(int memberId);
}

class MemberRemoteDataSourceImpl implements MemberRemoteDataSource {
  MemberRemoteDataSourceImpl(ApiClient apiClient, AppLogger logger)
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

  static const String _logContext = 'MemberRemoteDataSource';

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

  @override
  Future<void> createMember(MemberDraft draft) {
    return _writer.post(ApiConstants.members, MemberModel.bodyFromDraft(draft));
  }

  @override
  Future<void> updateMember(int memberId, MemberDraft draft) {
    return _writer.patch(
      ApiConstants.member(memberId),
      body: MemberModel.bodyFromDraft(draft),
    );
  }

  @override
  Future<void> setMemberActive(int memberId, {required bool isActive}) {
    return _writer.patch(
      isActive
          ? ApiConstants.memberReactivation(memberId)
          : ApiConstants.memberDeactivation(memberId),
    );
  }

  @override
  Future<void> assignFamilyGroup(int memberId, int familyGroupId) {
    return _writer.patch(
      ApiConstants.memberFamilyGroup(memberId),
      body: MemberModel.bodyForFamilyGroup(familyGroupId),
    );
  }

  @override
  Future<void> removeFromFamilyGroup(int memberId) {
    return _writer.delete(ApiConstants.memberFamilyGroup(memberId));
  }
}
