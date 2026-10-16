import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/usecases/load_members_use_case.dart';
import '../../../members/domain/usecases/watch_roster_changes_use_case.dart';
import '../../domain/usecases/watch_payment_changes_use_case.dart';
import 'admin_payments_state.dart';

class AdminPaymentsCubit extends Cubit<AdminPaymentsState> {
  final LoadMembersUseCase _loadMembers;
  late final List<StreamSubscription<void>> _changeSubscriptions;

  AdminPaymentsCubit({
    required LoadMembersUseCase loadMembers,
    required WatchRosterChangesUseCase watchRosterChanges,
    required WatchPaymentChangesUseCase watchPaymentChanges,
  })  : _loadMembers = loadMembers,
        super(const AdminPaymentsLoading()) {
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

    if (_lastLoadedRoster == null) emit(const AdminPaymentsLoading());

    final result = await _loadMembers();

    _isLoading = false;
    if (isClosed) return;

    final AdminPaymentsState next = result.fold(_failureFrom, _readyFrom);

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

  AdminPaymentsReady? get _lastLoadedRoster {
    final current = state;
    if (current is AdminPaymentsReady) return current;
    if (current is AdminPaymentsFailure) return current.previous;

    return null;
  }

  void _emitRoster(AdminPaymentsReady roster) {
    final current = state;

    emit(current is AdminPaymentsFailure ? current.withRoster(roster) : roster);
  }

  AdminPaymentsFailure _failureFrom(Failure failure) {
    _failedAttempts++;

    return AdminPaymentsFailure(
      failure.userMessage,
      previous: _lastLoadedRoster,
      attempt: _failedAttempts,
    );
  }

  AdminPaymentsReady _readyFrom(List<Member> members) {
    return AdminPaymentsReady(
      members: _sortedByName(members),
      searchQuery: _lastLoadedRoster?.searchQuery ?? '',
    );
  }

  List<Member> _sortedByName(List<Member> members) {
    return [...members]..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }
}
