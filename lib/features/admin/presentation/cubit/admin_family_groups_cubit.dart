import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../family_groups/domain/entities/family_group_candidates.dart';
import '../../../family_groups/domain/usecases/load_family_group_candidates_use_case.dart';
import '../../../family_groups/domain/usecases/watch_family_group_changes_use_case.dart';
import '../../../members/domain/usecases/watch_roster_changes_use_case.dart';
import '../../../payments/domain/usecases/watch_payment_changes_use_case.dart';
import 'admin_family_groups_state.dart';

class AdminFamilyGroupsCubit extends Cubit<AdminFamilyGroupsState> {
  final LoadFamilyGroupCandidatesUseCase _loadGroups;
  late final List<StreamSubscription<void>> _changeSubscriptions;

  AdminFamilyGroupsCubit({
    required LoadFamilyGroupCandidatesUseCase loadGroups,
    required WatchRosterChangesUseCase watchRosterChanges,
    required WatchFamilyGroupChangesUseCase watchGroupChanges,
    required WatchPaymentChangesUseCase watchPaymentChanges,
  })  : _loadGroups = loadGroups,
        super(const AdminFamilyGroupsLoading()) {
    _changeSubscriptions = [
      watchRosterChanges().listen((_) => _reloadOnChange()),
      watchGroupChanges().listen((_) => _reloadOnChange()),
      watchPaymentChanges().listen((_) => _reloadOnChange()),
    ];
  }

  bool _isLoading = false;
  bool _changedWhileLoading = false;

  @override
  Future<void> close() async {
    await Future.wait(
      _changeSubscriptions.map((subscription) => subscription.cancel()),
    );

    return super.close();
  }

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    if (_lastLoaded == null) emit(const AdminFamilyGroupsLoading());

    final result = await _loadGroups();
    _isLoading = false;
    if (isClosed) return;

    emit(result.fold(_failureFrom, _readyFrom));
    if (_changedWhileLoading) await _reloadOnChange();
  }

  void search(String query) {
    final loaded = _lastLoaded;
    if (loaded == null) return;

    emit(loaded.copyWith(searchQuery: query));
  }

  void clearSearch() => search('');

  Future<void> _reloadOnChange() async {
    _changedWhileLoading = _isLoading;
    if (_isLoading) return;

    await load();
  }

  AdminFamilyGroupsReady? get _lastLoaded {
    final current = state;
    if (current is AdminFamilyGroupsReady) return current;
    if (current is AdminFamilyGroupsFailure) return current.previous;

    return null;
  }

  AdminFamilyGroupsState _failureFrom(Failure failure) =>
      AdminFamilyGroupsFailure(failure.userMessage, previous: _lastLoaded);

  AdminFamilyGroupsState _readyFrom(FamilyGroupCandidates candidates) =>
      AdminFamilyGroupsReady(
        groups: candidates.details,
        searchQuery: _lastLoaded?.searchQuery ?? '',
      );
}
