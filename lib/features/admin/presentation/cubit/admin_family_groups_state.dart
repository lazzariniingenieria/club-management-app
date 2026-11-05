import 'package:equatable/equatable.dart';

import '../../../family_groups/domain/entities/family_group_detail.dart';

sealed class AdminFamilyGroupsState extends Equatable {
  const AdminFamilyGroupsState();

  @override
  List<Object?> get props => [];
}

class AdminFamilyGroupsLoading extends AdminFamilyGroupsState {
  const AdminFamilyGroupsLoading();
}

class AdminFamilyGroupsReady extends AdminFamilyGroupsState {
  final List<FamilyGroupDetail> groups;
  final String searchQuery;

  const AdminFamilyGroupsReady({required this.groups, this.searchQuery = ''});

  List<FamilyGroupDetail> get visibleGroups =>
      groups.where((group) => group.matches(searchQuery)).toList();

  bool get hasSearchQuery => searchQuery.trim().isNotEmpty;

  AdminFamilyGroupsReady copyWith({String? searchQuery}) {
    return AdminFamilyGroupsReady(
      groups: groups,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [groups, searchQuery];
}

class AdminFamilyGroupsFailure extends AdminFamilyGroupsState {
  final String message;
  final AdminFamilyGroupsReady? previous;

  const AdminFamilyGroupsFailure(this.message, {this.previous});

  @override
  List<Object?> get props => [message, previous];
}
