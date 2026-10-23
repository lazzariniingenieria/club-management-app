import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';

class FamilyGroupBuildRequest extends Equatable {
  final List<int> memberIds;
  final String name;

  const FamilyGroupBuildRequest({required this.memberIds, required this.name});

  String? get trimmedName {
    final trimmed = name.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props => [memberIds, name];
}

class FamilyGroupBuildProgress extends Equatable {
  final int? familyGroupId;
  final Set<int> assignedMemberIds;

  const FamilyGroupBuildProgress({
    this.familyGroupId,
    this.assignedMemberIds = const {},
  });

  bool get hasCreatedGroup => familyGroupId != null;

  FamilyGroupBuildProgress withGroup(int familyGroupId) =>
      FamilyGroupBuildProgress(
        familyGroupId: familyGroupId,
        assignedMemberIds: assignedMemberIds,
      );

  FamilyGroupBuildProgress withAssigned(Iterable<int> memberIds) =>
      FamilyGroupBuildProgress(
        familyGroupId: familyGroupId,
        assignedMemberIds: {...assignedMemberIds, ...memberIds},
      );

  List<int> pendingOf(FamilyGroupBuildRequest request) => request.memberIds
      .where((memberId) => !assignedMemberIds.contains(memberId))
      .toList();

  @override
  List<Object?> get props => [familyGroupId, assignedMemberIds];
}

sealed class FamilyGroupBuildResult extends Equatable {
  const FamilyGroupBuildResult();
}

class FamilyGroupBuilt extends FamilyGroupBuildResult {
  final int familyGroupId;

  const FamilyGroupBuilt(this.familyGroupId);

  @override
  List<Object?> get props => [familyGroupId];
}

class FamilyGroupBuildFailed extends FamilyGroupBuildResult {
  final Failure failure;
  final FamilyGroupBuildProgress progress;

  const FamilyGroupBuildFailed(this.failure, this.progress);

  bool get isPartial => progress.hasCreatedGroup;

  bool get isCreationUnconfirmed =>
      !isPartial && failure is ResponseTimeoutFailure;

  @override
  List<Object?> get props => [failure, progress];
}
