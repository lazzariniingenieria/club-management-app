import 'package:equatable/equatable.dart';

import '../../domain/entities/member.dart';
import '../../domain/entities/member_collection_filter.dart';

sealed class AdminPaymentsState extends Equatable {
  const AdminPaymentsState();

  @override
  List<Object?> get props => [];
}

class AdminPaymentsLoading extends AdminPaymentsState {
  const AdminPaymentsLoading();
}

class AdminPaymentsReady extends AdminPaymentsState {
  final List<Member> members;
  final Set<int> selectedMemberIds;
  final String searchQuery;

  const AdminPaymentsReady({
    required this.members,
    this.selectedMemberIds = const {},
    this.searchQuery = '',
  });

  int countFor(MemberCollectionFilter filter) => members
      .where((member) => filter.matches(member, selectedMemberIds))
      .length;

  List<Member> visibleMembers(MemberCollectionFilter filter) {
    return members
        .where((member) => filter.matches(member, selectedMemberIds))
        .where((member) => member.matches(searchQuery))
        .toList();
  }

  bool isSelected(Member member) => selectedMemberIds.contains(member.id);

  bool get hasSearchQuery => searchQuery.trim().isNotEmpty;

  AdminPaymentsReady copyWith({
    Set<int>? selectedMemberIds,
    String? searchQuery,
  }) {
    return AdminPaymentsReady(
      members: members,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [members, selectedMemberIds, searchQuery];
}

class AdminPaymentsFailure extends AdminPaymentsState {
  final String message;

  const AdminPaymentsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
