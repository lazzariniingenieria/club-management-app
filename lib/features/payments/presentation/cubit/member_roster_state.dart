import 'package:equatable/equatable.dart';

import '../../../members/domain/entities/member.dart';
import '../../../members/domain/entities/member_collection_filter.dart';

sealed class MemberRosterState extends Equatable {
  const MemberRosterState();

  @override
  List<Object?> get props => [];
}

class MemberRosterLoading extends MemberRosterState {
  const MemberRosterLoading();
}

class MemberRosterReady extends MemberRosterState {
  final List<Member> members;
  final String searchQuery;

  const MemberRosterReady({required this.members, this.searchQuery = ''});

  int countFor(MemberCollectionFilter filter) =>
      members.where(filter.matches).length;

  List<Member> visibleMembers(MemberCollectionFilter filter) {
    return members
        .where(filter.matches)
        .where((member) => member.matches(searchQuery))
        .toList();
  }

  bool get hasSearchQuery => searchQuery.trim().isNotEmpty;

  MemberRosterReady copyWith({String? searchQuery}) {
    return MemberRosterReady(
      members: members,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [members, searchQuery];
}

class MemberRosterFailure extends MemberRosterState {
  final String message;
  final MemberRosterReady? previous;
  final int attempt;

  const MemberRosterFailure(
    this.message, {
    this.previous,
    this.attempt = 1,
  });

  MemberRosterFailure withRoster(MemberRosterReady roster) =>
      MemberRosterFailure(message, previous: roster, attempt: attempt);

  bool isNewerThan(MemberRosterState other) =>
      other is! MemberRosterFailure || other.attempt != attempt;

  @override
  List<Object?> get props => [message, previous, attempt];
}
