import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../domain/entities/member.dart';
import '../../domain/usecases/load_members_use_case.dart';
import 'admin_payments_state.dart';

class AdminPaymentsCubit extends Cubit<AdminPaymentsState> {
  final LoadMembersUseCase _loadMembers;

  AdminPaymentsCubit(this._loadMembers) : super(const AdminPaymentsLoading());

  Future<void> load() async {
    final previous =
        state is AdminPaymentsReady ? state as AdminPaymentsReady : null;
    if (previous == null) emit(const AdminPaymentsLoading());

    final result = await _loadMembers();

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => AdminPaymentsFailure(failure.userMessage),
        (members) => _readyFrom(members, previous),
      ),
    );
  }

  void search(String query) {
    final current = state;
    if (current is! AdminPaymentsReady) return;

    emit(current.copyWith(searchQuery: query));
  }

  void clearSearch() => search('');

  void toggleReportSelection(int memberId) {
    final current = state;
    if (current is! AdminPaymentsReady) return;

    final selection = Set<int>.from(current.selectedMemberIds);
    if (!selection.remove(memberId)) selection.add(memberId);

    emit(current.copyWith(selectedMemberIds: selection));
  }

  AdminPaymentsReady _readyFrom(
    List<Member> members,
    AdminPaymentsReady? previous,
  ) {
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
