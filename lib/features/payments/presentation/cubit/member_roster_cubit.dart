import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/usecases/load_members_use_case.dart';
import '../../../members/domain/usecases/watch_roster_changes_use_case.dart';
import '../../domain/usecases/watch_payment_changes_use_case.dart';
import 'member_roster_state.dart';

class MemberRosterCubit extends Cubit<MemberRosterState> {
  final LoadMembersUseCase _loadMembers;
  late final List<StreamSubscription<void>> _changeSubscriptions;

  MemberRosterCubit({
    required LoadMembersUseCase loadMembers,
    required WatchRosterChangesUseCase watchRosterChanges,
    required WatchPaymentChangesUseCase watchPaymentChanges,
  })  : _loadMembers = loadMembers,
        super(const MemberRosterLoading()) {
    _changeSubscriptions = [
      watchRosterChanges().listen((_) => _reloadOnChange()),
      watchPaymentChanges().listen((_) => _reloadOnChange()),
    ];
  }

  bool _isLoading = false;
  bool _changedWhileLoading = false;
  int _failedAttempts = 0;

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

    if (_lastLoadedRoster == null) emit(const MemberRosterLoading());

    final result = await _loadMembers();

    _isLoading = false;
    if (isClosed) return;

    final MemberRosterState next = result.fold(_failureFrom, _readyFrom);

    emit(next);
    if (_changedWhileLoading) await _reloadOnChange();
  }

  Future<void> _reloadOnChange() async {
    _changedWhileLoading = _isLoading;
    if (_isLoading) return;

    await load();
  }

  void search(String query) {
    final roster = _lastLoadedRoster;
    if (roster == null) return;

    _emitRoster(roster.copyWith(searchQuery: query));
  }

  void clearSearch() => search('');

  MemberRosterReady? get _lastLoadedRoster {
    final current = state;
    if (current is MemberRosterReady) return current;
    if (current is MemberRosterFailure) return current.previous;

    return null;
  }

  void _emitRoster(MemberRosterReady roster) {
    final current = state;

    emit(current is MemberRosterFailure ? current.withRoster(roster) : roster);
  }

  MemberRosterFailure _failureFrom(Failure failure) {
    _failedAttempts++;

    return MemberRosterFailure(
      failure.userMessage,
      previous: _lastLoadedRoster,
      attempt: _failedAttempts,
    );
  }

  MemberRosterReady _readyFrom(List<Member> members) {
    return MemberRosterReady(
      members: _sortedByName(members),
      searchQuery: _lastLoadedRoster?.searchQuery ?? '',
    );
  }

  List<Member> _sortedByName(List<Member> members) {
    return [...members]..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }
}
