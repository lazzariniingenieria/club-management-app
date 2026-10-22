import 'package:equatable/equatable.dart';

import '../../../members/domain/entities/member.dart';
import 'family_group.dart';

class FamilyGroupDetail extends Equatable {
  final FamilyGroup group;
  final List<Member> members;

  const FamilyGroupDetail({required this.group, required this.members});

  factory FamilyGroupDetail.fromRoster(FamilyGroup group, List<Member> roster) {
    final members = roster
        .where((member) => member.familyGroupId == group.id)
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

    return FamilyGroupDetail(group: group, members: members);
  }

  bool includes(Member member) => members.any((each) => each.id == member.id);

  bool get hasSingleMember => members.length == 1;

  @override
  List<Object?> get props => [group, members];
}
