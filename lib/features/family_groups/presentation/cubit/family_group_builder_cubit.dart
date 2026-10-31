import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/family_group_build.dart';
import '../../domain/usecases/build_family_group_use_case.dart';
import '../../domain/usecases/join_family_group_use_case.dart';
import 'family_group_builder_state.dart';

class FamilyGroupBuilderCubit extends Cubit<FamilyGroupBuilderState> {
  final BuildFamilyGroupUseCase _buildGroup;
  final JoinFamilyGroupUseCase _joinGroup;

  FamilyGroupBuilderCubit({
    required BuildFamilyGroupUseCase buildGroup,
    required JoinFamilyGroupUseCase joinGroup,
  })  : _buildGroup = buildGroup,
        _joinGroup = joinGroup,
        super(const FamilyGroupBuilderState());

  void reset() {
    if (!state.isSaving) emit(const FamilyGroupBuilderState());
  }

  Future<bool> build(FamilyGroupBuildRequest request) async {
    emit(state.saving());

    final result = await _buildGroup(request);
    if (isClosed) return result is FamilyGroupBuilt;

    emit(_stateAfter(result));

    return result is FamilyGroupBuilt;
  }

  Future<bool> join(int memberId, int familyGroupId) async {
    emit(state.saving());

    final result = await _joinGroup(memberId, familyGroupId);
    final failure = result.getLeft().toNullable();
    if (isClosed) return failure == null;

    emit(
      state.settled(
        failure == null
            ? FamilyGroupSaveStatus.done
            : FamilyGroupSaveStatus.failed,
        failure: failure,
      ),
    );

    return failure == null;
  }

  static FamilyGroupBuilderState _stateAfter(FamilyGroupBuildResult result) {
    return switch (result) {
      FamilyGroupBuilt() =>
        const FamilyGroupBuilderState(status: FamilyGroupSaveStatus.done),
      FamilyGroupBuildFailed(:final failure) => FamilyGroupBuilderState(
          status: FamilyGroupSaveStatus.failed,
          failure: failure,
          isCreationUnconfirmed: result.isCreationUnconfirmed,
          isStale: result.isStale,
        ),
    };
  }
}
