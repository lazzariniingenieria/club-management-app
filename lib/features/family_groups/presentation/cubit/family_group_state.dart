import 'package:equatable/equatable.dart';

import '../../domain/entities/family_group_detail.dart';

sealed class FamilyGroupState extends Equatable {
  const FamilyGroupState();

  @override
  List<Object?> get props => [];
}

class FamilyGroupLoading extends FamilyGroupState {
  const FamilyGroupLoading();
}

class FamilyGroupReady extends FamilyGroupState {
  final FamilyGroupDetail detail;

  const FamilyGroupReady(this.detail);

  @override
  List<Object?> get props => [detail];
}

class FamilyGroupFailure extends FamilyGroupState {
  final bool isOffline;

  const FamilyGroupFailure({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}

class FamilyGroupMissing extends FamilyGroupState {
  const FamilyGroupMissing();
}
