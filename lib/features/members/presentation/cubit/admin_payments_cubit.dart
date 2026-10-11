import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/member.dart';
import '../../domain/usecases/load_members_use_case.dart';
import 'admin_payments_state.dart';

class AdminPaymentsCubit extends Cubit<AdminPaymentsState> {
  final LoadMembersUseCase _loadMembers;

  AdminPaymentsCubit(this._loadMembers) : super(const AdminPaymentsLoading());

  bool _isLoading = false;
  int _failedAttempts = 0;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;

    if (_lastLoadedRoster == null) emit(const AdminPaymentsLoading());

    final result = await _loadMembers();

    _isLoading = false;
    if (isClosed) return;

    final AdminPaymentsState next = result.fold(_failureFrom, _readyFrom);

    emit(next);
  }

  void search(String query) {
    final roster = _lastLoadedRoster;
    if (roster == null) return;

    _emitRoster(roster.copyWith(searchQuery: query));
  }

  void clearSearch() => search('');

  void toggleReportSelection(int memberId) {
    final roster = _lastLoadedRoster;
    if (roster == null) return;

    final selection = Set<int>.from(roster.selectedMemberIds);
    if (!selection.remove(memberId)) selection.add(memberId);

    _emitRoster(roster.copyWith(selectedMemberIds: selection));
  }

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
    final previous = _lastLoadedRoster;
    final knownIds = members.map((member) => member.id).toSet();

    return AdminPaymentsReady(
      members: _sortedByName(members),
      selectedMemberIds:
          previous?.selectedMemberIds.intersection(knownIds) ?? const {},
      searchQuery: previous?.searchQuery ?? '',
    );
  }

  List<Member> _sortedByName(List<Member> members) {
    return [...members]..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }
}
