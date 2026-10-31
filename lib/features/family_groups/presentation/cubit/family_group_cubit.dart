import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/usecases/watch_roster_changes_use_case.dart';
import '../../domain/usecases/delete_family_group_use_case.dart';
import '../../domain/usecases/leave_family_group_use_case.dart';
import '../../domain/usecases/load_family_group_detail_use_case.dart';
import '../../domain/usecases/rename_family_group_use_case.dart';
import '../../domain/usecases/watch_family_group_changes_use_case.dart';
import 'family_group_state.dart';

class FamilyGroupCubit extends Cubit<FamilyGroupState> {
  final LoadFamilyGroupDetailUseCase _loadDetail;
  final RenameFamilyGroupUseCase _rename;
  final LeaveFamilyGroupUseCase _leave;
  final DeleteFamilyGroupUseCase _delete;
  late final List<StreamSubscription<void>> _changeSubscriptions;

  FamilyGroupCubit({
    required LoadFamilyGroupDetailUseCase loadDetail,
    required RenameFamilyGroupUseCase rename,
    required LeaveFamilyGroupUseCase leave,
    required DeleteFamilyGroupUseCase delete,
    required WatchRosterChangesUseCase watchRosterChanges,
    required WatchFamilyGroupChangesUseCase watchGroupChanges,
  })  : _loadDetail = loadDetail,
        _rename = rename,
        _leave = leave,
        _delete = delete,
        super(const FamilyGroupLoading()) {
    _changeSubscriptions = [
      watchRosterChanges().listen((_) => _reloadOnChange()),
      watchGroupChanges().listen((_) => _reloadOnChange()),
    ];
  }

  int? _familyGroupId;
  bool _isLoading = false;
  bool _changedWhileLoading = false;

  @override
  Future<void> close() async {
    await Future.wait(
      _changeSubscriptions.map((subscription) => subscription.cancel()),
    );

    return super.close();
  }

  Future<void> load(int familyGroupId) async {
    _familyGroupId = familyGroupId;
    _isLoading = true;
    if (state is! FamilyGroupReady) emit(const FamilyGroupLoading());

    final result = await _loadDetail(familyGroupId);
    _isLoading = false;
    if (isClosed) return;

    emit(result.fold<FamilyGroupState>(_stateFor, FamilyGroupReady.new));
    if (_changedWhileLoading) await _reloadOnChange();
  }

  Future<void> reload() async {
    final familyGroupId = _familyGroupId;
    if (familyGroupId != null) await load(familyGroupId);
  }

  Future<Failure?> rename(String name) async {
    final familyGroupId = _familyGroupId;
    if (familyGroupId == null) return null;

    final result = await _rename(familyGroupId, name);

    return result.getLeft().toNullable();
  }

  Future<Failure?> remove(Member member) async {
    final result = await _leave(member.id);
    final failure = result.getLeft().toNullable();
    if (failure is! ResponseTimeoutFailure) return failure;

    await reload();

    return _stillIncludes(member) ? failure : null;
  }

  Future<Failure?> delete() async {
    final familyGroupId = _familyGroupId;
    if (familyGroupId == null) return null;

    final result = await _delete(familyGroupId);
    final failure = result.getLeft().toNullable();
    if (failure is NotFoundFailure) return null;
    if (failure is! ResponseTimeoutFailure) return failure;

    await reload();

    return state is FamilyGroupMissing ? null : failure;
  }

  bool _stillIncludes(Member member) {
    final current = state;

    return current is FamilyGroupReady && current.detail.includes(member);
  }

  Future<void> _reloadOnChange() async {
    _changedWhileLoading = _isLoading;
    if (_isLoading) return;

    await reload();
  }

  static FamilyGroupState _stateFor(Failure failure) {
    return switch (failure) {
      NotFoundFailure() => const FamilyGroupMissing(),
      NetworkFailure() => const FamilyGroupFailure(isOffline: true),
      _ => const FamilyGroupFailure(isOffline: false),
    };
  }
}
