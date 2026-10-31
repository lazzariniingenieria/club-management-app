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

  bool get isEmpty => members.isEmpty;

  bool get hasOverdueMember =>
      members.any((member) => member.isActive && member.isOverdue);

  Member? get paymentAnchor {
    final active = members.where((member) => member.isActive).toList()
      ..sort(_mostOverdueFirst);

    return active.length < 2 ? null : active.first;
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    final groupName = group.name?.toLowerCase() ?? '';

    return groupName.contains(normalized) ||
        members.any((member) => member.matches(query));
  }

  static int byFirstMember(FamilyGroupDetail a, FamilyGroupDetail b) {
    if (a.isEmpty || b.isEmpty) {
      return a.isEmpty == b.isEmpty
          ? a.group.id.compareTo(b.group.id)
          : (a.isEmpty ? 1 : -1);
    }

    return a.members.first.sortKey.compareTo(b.members.first.sortKey);
  }

  static int _mostOverdueFirst(Member a, Member b) {
    final byDays = b.daysOverdue.compareTo(a.daysOverdue);

    return byDays != 0 ? byDays : a.sortKey.compareTo(b.sortKey);
  }

  @override
  List<Object?> get props => [group, members];
}
