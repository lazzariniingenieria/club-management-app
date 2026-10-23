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

  void prepareFor(List<int> memberIds) {
    if (state.belongsTo(memberIds)) return;

    emit(FamilyGroupBuilderState(memberIds: memberIds));
  }

  Future<bool> build(FamilyGroupBuildRequest request) async {
    prepareFor(request.memberIds);
    emit(state.saving());

    final result = await _buildGroup(request, progress: state.progress);
    if (isClosed) return result is FamilyGroupBuilt;

    emit(_stateAfter(result, request.memberIds));

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

  static FamilyGroupBuilderState _stateAfter(
    FamilyGroupBuildResult result,
    List<int> memberIds,
  ) {
    return switch (result) {
      FamilyGroupBuilt() => FamilyGroupBuilderState(
          status: FamilyGroupSaveStatus.done,
          memberIds: memberIds,
        ),
      FamilyGroupBuildFailed(:final failure, :final progress) =>
        FamilyGroupBuilderState(
          status: FamilyGroupSaveStatus.failed,
          failure: failure,
          memberIds: memberIds,
          progress: progress,
          isCreationUnconfirmed: result.isCreationUnconfirmed,
        ),
    };
  }
}
