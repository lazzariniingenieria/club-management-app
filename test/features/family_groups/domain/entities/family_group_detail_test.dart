import 'package:club_management_app/features/family_groups/domain/entities/family_group.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group_detail.dart';
import 'package:club_management_app/features/members/data/models/member_model.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:flutter_test/flutter_test.dart';

MemberModel _member(int id, String first, String last, {int? groupId}) {
  return MemberModel(
    id: id,
    firstName: first,
    lastName: last,
    dni: '${30000000 + id}',
    status: MemberStatus.active,
    daysOverdue: 0,
    familyGroupId: groupId,
  );
}

void main() {
  final roster = [
    _member(1, 'Tomás', 'Gómez', groupId: 7),
    _member(2, 'Laura', 'Gómez', groupId: 7),
    _member(3, 'Sofía', 'Acosta', groupId: 8),
    _member(4, 'Juan', 'Álvarez'),
  ];

  test('the members are the roster filtered by familyGroupId, by surname', () {
    final detail = FamilyGroupDetail.fromRoster(
      const FamilyGroup(id: 7, name: 'Familia Gómez'),
      roster,
    );

    expect(detail.members.map((m) => m.firstName), ['Laura', 'Tomás']);
    expect(detail.includes(roster[0]), isTrue);
    expect(detail.includes(roster[2]), isFalse);
  });

  test('flags a group with a single member', () {
    final detail =
        FamilyGroupDetail.fromRoster(const FamilyGroup(id: 8), roster);

    expect(detail.hasSingleMember, isTrue);
  });
}
