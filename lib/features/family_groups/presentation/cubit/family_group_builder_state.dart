import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/family_group_build.dart';

enum FamilyGroupSaveStatus { idle, saving, failed, done }

class FamilyGroupBuilderState extends Equatable {
  final FamilyGroupSaveStatus status;
  final Failure? failure;
  final List<int> memberIds;
  final FamilyGroupBuildProgress progress;
  final bool isCreationUnconfirmed;

  const FamilyGroupBuilderState({
    this.status = FamilyGroupSaveStatus.idle,
    this.failure,
    this.memberIds = const [],
    this.progress = const FamilyGroupBuildProgress(),
    this.isCreationUnconfirmed = false,
  });

  bool get isSaving => status == FamilyGroupSaveStatus.saving;

  bool get isPartial => progress.hasCreatedGroup;

  bool get isOffline => failure is NetworkFailure;

  bool belongsTo(List<int> memberIds) => listEquals(this.memberIds, memberIds);

  FamilyGroupBuilderState saving() => settled(FamilyGroupSaveStatus.saving);

  FamilyGroupBuilderState settled(
    FamilyGroupSaveStatus status, {
    Failure? failure,
  }) {
    return FamilyGroupBuilderState(
      status: status,
      failure: failure,
      memberIds: memberIds,
      progress: progress,
    );
  }

  @override
  List<Object?> get props =>
      [status, failure, memberIds, progress, isCreationUnconfirmed];
}
