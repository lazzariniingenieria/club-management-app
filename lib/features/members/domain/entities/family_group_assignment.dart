import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';

class FamilyGroupAssignment extends Equatable {
  final Set<int> assignedMemberIds;
  final Failure? failure;

  const FamilyGroupAssignment({
    required this.assignedMemberIds,
    this.failure,
  });

  bool get mayHaveChangedRoster =>
      assignedMemberIds.isNotEmpty || failure is ResponseTimeoutFailure;

  @override
  List<Object?> get props => [assignedMemberIds, failure];
}
