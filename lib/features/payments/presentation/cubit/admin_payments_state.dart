import 'package:equatable/equatable.dart';

import '../../../members/domain/entities/member.dart';
import '../../../members/domain/entities/member_collection_filter.dart';

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
  final String searchQuery;

  const AdminPaymentsReady({required this.members, this.searchQuery = ''});

  int countFor(MemberCollectionFilter filter) =>
      members.where(filter.matches).length;

  List<Member> visibleMembers(MemberCollectionFilter filter) {
    return members
        .where(filter.matches)
        .where((member) => member.matches(searchQuery))
        .toList();
  }

  bool get hasSearchQuery => searchQuery.trim().isNotEmpty;

  AdminPaymentsReady copyWith({String? searchQuery}) {
    return AdminPaymentsReady(
      members: members,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [members, searchQuery];
}

class AdminPaymentsFailure extends AdminPaymentsState {
  final String message;
  final AdminPaymentsReady? previous;
  final int attempt;

  const AdminPaymentsFailure(
    this.message, {
    this.previous,
    this.attempt = 1,
  });

  AdminPaymentsFailure withRoster(AdminPaymentsReady roster) =>
      AdminPaymentsFailure(message, previous: roster, attempt: attempt);

  bool isNewerThan(AdminPaymentsState other) =>
      other is! AdminPaymentsFailure || other.attempt != attempt;

  @override
  List<Object?> get props => [message, previous, attempt];
}
