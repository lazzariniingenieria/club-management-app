import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';

enum FamilyGroupSaveStatus { idle, saving, failed, done }

class FamilyGroupBuilderState extends Equatable {
  final FamilyGroupSaveStatus status;
  final Failure? failure;
  final bool isCreationUnconfirmed;
  final bool isStale;

  const FamilyGroupBuilderState({
    this.status = FamilyGroupSaveStatus.idle,
    this.failure,
    this.isCreationUnconfirmed = false,
    this.isStale = false,
  });

  bool get isSaving => status == FamilyGroupSaveStatus.saving;

  bool get isOffline => failure is NetworkFailure;

  FamilyGroupBuilderState saving() =>
      const FamilyGroupBuilderState(status: FamilyGroupSaveStatus.saving);

  FamilyGroupBuilderState settled(
    FamilyGroupSaveStatus status, {
    Failure? failure,
  }) {
    return FamilyGroupBuilderState(status: status, failure: failure);
  }

  @override
  List<Object?> get props => [status, failure, isCreationUnconfirmed, isStale];
}
