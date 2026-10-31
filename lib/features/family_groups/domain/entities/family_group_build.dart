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

  const FamilyGroupBuildFailed(this.failure);

  bool get isCreationUnconfirmed => failure is ResponseTimeoutFailure;

  bool get isStale => failure is ConflictFailure;

  @override
  List<Object?> get props => [failure];
}
