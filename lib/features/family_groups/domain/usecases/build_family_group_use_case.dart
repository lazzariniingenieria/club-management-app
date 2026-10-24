import 'package:fpdart/fpdart.dart';

import '../../../members/domain/repositories/member_repository.dart';
import '../entities/family_group_build.dart';
import '../repositories/family_group_repository.dart';

class BuildFamilyGroupUseCase {
  final FamilyGroupRepository groups;
  final MemberRepository members;

  BuildFamilyGroupUseCase({required this.groups, required this.members});

  Future<FamilyGroupBuildResult> call(
    FamilyGroupBuildRequest request, {
    FamilyGroupBuildProgress progress = const FamilyGroupBuildProgress(),
  }) async {
    final withGroup = await _ensureGroup(request, progress);

    return withGroup.fold<Future<FamilyGroupBuildResult>>(
      (failed) async => failed,
      (progress) => _assignPending(request, progress),
    );
  }

  Future<Either<FamilyGroupBuildFailed, FamilyGroupBuildProgress>> _ensureGroup(
    FamilyGroupBuildRequest request,
    FamilyGroupBuildProgress progress,
  ) async {
    if (progress.hasCreatedGroup) return Right(progress);

    final created = await groups.createGroup(name: request.trimmedName);

    return created.bimap(
      (failure) => FamilyGroupBuildFailed(failure, progress),
      (group) => progress.withGroup(group.id),
    );
  }

  Future<FamilyGroupBuildResult> _assignPending(
    FamilyGroupBuildRequest request,
    FamilyGroupBuildProgress progress,
  ) async {
    final familyGroupId = progress.familyGroupId!;
    final assignment = await members.assignFamilyGroupToAll(
      progress.pendingOf(request),
      familyGroupId,
    );
    final failure = assignment.failure;
    if (failure == null) return FamilyGroupBuilt(familyGroupId);

    return FamilyGroupBuildFailed(
      failure,
      progress.withAssigned(assignment.assignedMemberIds),
    );
  }
}
