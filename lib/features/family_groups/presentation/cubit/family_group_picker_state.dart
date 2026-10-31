import 'package:equatable/equatable.dart';

import '../../domain/entities/family_group_candidates.dart';

sealed class FamilyGroupPickerState extends Equatable {
  const FamilyGroupPickerState();

  @override
  List<Object?> get props => [];
}

class FamilyGroupPickerLoading extends FamilyGroupPickerState {
  const FamilyGroupPickerLoading();
}

class FamilyGroupPickerReady extends FamilyGroupPickerState {
  final FamilyGroupCandidates candidates;
  final String searchQuery;

  const FamilyGroupPickerReady({
    required this.candidates,
    this.searchQuery = '',
  });

  bool get hasSearchQuery => searchQuery.trim().isNotEmpty;

  FamilyGroupPickerReady withQuery(String query) =>
      FamilyGroupPickerReady(candidates: candidates, searchQuery: query);

  @override
  List<Object?> get props => [candidates, searchQuery];
}

class FamilyGroupPickerFailure extends FamilyGroupPickerState {
  final bool isOffline;

  const FamilyGroupPickerFailure({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}
