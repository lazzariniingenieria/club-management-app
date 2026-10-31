import 'package:equatable/equatable.dart';

import '../../../members/domain/entities/member.dart';
import 'family_group.dart';

class FamilyGroupCandidates extends Equatable {
  final List<Member> roster;
  final List<FamilyGroup> groups;

  const FamilyGroupCandidates({required this.roster, required this.groups});

  Member? memberById(int memberId) {
    for (final member in roster) {
      if (member.id == memberId) return member;
    }

    return null;
  }

  FamilyGroup? groupOf(Member member) => groupById(member.familyGroupId);

  FamilyGroup? groupById(int? familyGroupId) {
    if (familyGroupId == null) return null;

    for (final group in groups) {
      if (group.id == familyGroupId) return group;
    }

    return FamilyGroup(id: familyGroupId);
  }

  List<Member> membersOf(int familyGroupId) => roster
      .where((member) => member.familyGroupId == familyGroupId)
      .toList();

  @override
  List<Object?> get props => [roster, groups];
}
