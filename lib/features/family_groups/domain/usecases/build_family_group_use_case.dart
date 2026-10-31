import '../../../../core/errors/failures.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../entities/family_group_build.dart';
import '../repositories/family_group_repository.dart';

class BuildFamilyGroupUseCase {
  final FamilyGroupRepository groups;
  final MemberRepository members;

  BuildFamilyGroupUseCase({required this.groups, required this.members});

  Future<FamilyGroupBuildResult> call(FamilyGroupBuildRequest request) async {
    final created = await groups.createGroup(
      name: request.trimmedName,
      memberIds: request.memberIds,
    );
    final failure = created.getLeft().toNullable();
    if (failure == null) {
      members.notifyRosterChanged();

      return FamilyGroupBuilt(created.getRight().toNullable()!.id);
    }
    if (failure is! ResponseTimeoutFailure && failure is! ConflictFailure) {
      return FamilyGroupBuildFailed(failure);
    }

    return _afterUncertainFailure(request, failure);
  }

  Future<FamilyGroupBuildResult> _afterUncertainFailure(
    FamilyGroupBuildRequest request,
    Failure failure,
  ) async {
    members.notifyRosterChanged();
    final familyGroupId = await _sharedGroupOf(request.memberIds);

    return familyGroupId == null
        ? FamilyGroupBuildFailed(failure)
        : FamilyGroupBuilt(familyGroupId);
  }

  Future<int?> _sharedGroupOf(List<int> memberIds) async {
    final loaded = await Future.wait(memberIds.map(members.loadMember));
    final groupIds = <int?>{
      for (final member in loaded)
        member.fold<int?>((_) => null, (Member member) => member.familyGroupId),
    };

    return groupIds.length == 1 ? groupIds.single : null;
  }
}
