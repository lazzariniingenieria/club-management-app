import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/family_group.dart';
import '../../domain/usecases/load_family_group_use_case.dart';
import '../../domain/usecases/watch_family_group_changes_use_case.dart';

class FamilyGroupNameState extends Equatable {
  final bool isLoading;
  final FamilyGroup? group;

  const FamilyGroupNameState({this.isLoading = true, this.group});

  @override
  List<Object?> get props => [isLoading, group];
}

class FamilyGroupNameCubit extends Cubit<FamilyGroupNameState> {
  final LoadFamilyGroupUseCase _loadGroup;
  late final StreamSubscription<void> _changes;

  FamilyGroupNameCubit({
    required LoadFamilyGroupUseCase loadGroup,
    required WatchFamilyGroupChangesUseCase watchChanges,
  })  : _loadGroup = loadGroup,
        super(const FamilyGroupNameState()) {
    _changes = watchChanges().listen((_) => _reload());
  }

  int? _familyGroupId;

  @override
  Future<void> close() async {
    await _changes.cancel();

    return super.close();
  }

  Future<void> load(int familyGroupId) async {
    _familyGroupId = familyGroupId;
    final result = await _loadGroup(familyGroupId);
    if (isClosed) return;

    emit(
      FamilyGroupNameState(
        isLoading: false,
        group: result.getRight().toNullable(),
      ),
    );
  }

  Future<void> _reload() async {
    final familyGroupId = _familyGroupId;
    if (familyGroupId != null) await load(familyGroupId);
  }
}
