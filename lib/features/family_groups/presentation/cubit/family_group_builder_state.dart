import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/family_group_build.dart';

enum FamilyGroupSaveStatus { idle, saving, failed, done }

class FamilyGroupBuilderState extends Equatable {
  final FamilyGroupSaveStatus status;
  final Failure? failure;
  final FamilyGroupBuildProgress progress;

  const FamilyGroupBuilderState({
    this.status = FamilyGroupSaveStatus.idle,
    this.failure,
    this.progress = const FamilyGroupBuildProgress(),
  });

  bool get isSaving => status == FamilyGroupSaveStatus.saving;

  bool get isPartial => progress.hasCreatedGroup;

  bool get isOffline => failure is NetworkFailure;

  FamilyGroupBuilderState saving() => FamilyGroupBuilderState(
        status: FamilyGroupSaveStatus.saving,
        progress: progress,
      );

  @override
  List<Object?> get props => [status, failure, progress];
}
