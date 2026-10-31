import 'package:club_management_app/features/family_groups/domain/entities/family_group.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group_detail.dart';
import 'package:club_management_app/features/members/data/models/member_model.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:flutter_test/flutter_test.dart';

MemberModel _member(
  int id,
  String first,
  String last, {
  int? groupId,
  int daysOverdue = 0,
  MemberStatus status = MemberStatus.active,
}) {
  return MemberModel(
    id: id,
    firstName: first,
    lastName: last,
    dni: '${30000000 + id}',
    status: status,
    daysOverdue: daysOverdue,
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

  group('in the list of groups', () {
    FamilyGroupDetail groupOf(List<MemberModel> members) =>
        FamilyGroupDetail(group: const FamilyGroup(id: 9), members: members);

    test('is flagged en mora when an active member owes', () {
      expect(
        groupOf([_member(1, 'Ana', 'Ríos', daysOverdue: 30)]).hasOverdueMember,
        isTrue,
      );
      expect(
        groupOf([
          _member(
            1,
            'Ana',
            'Ríos',
            daysOverdue: 30,
            status: MemberStatus.inactive,
          ),
        ]).hasOverdueMember,
        isFalse,
      );
    });

    test('pays from the active member who owes the most', () {
      final detail = groupOf([
        _member(1, 'Ana', 'Ríos', daysOverdue: 10),
        _member(2, 'Bruno', 'Ríos', daysOverdue: 40),
        _member(
          3,
          'Carla',
          'Ríos',
          daysOverdue: 90,
          status: MemberStatus.inactive,
        ),
      ]);

      expect(detail.paymentAnchor?.id, 2);
    });

    test('offers no group payment with fewer than two active members', () {
      expect(groupOf([_member(1, 'Ana', 'Ríos')]).paymentAnchor, isNull);
    });

    test('matches its name or any member', () {
      final detail = FamilyGroupDetail(
        group: const FamilyGroup(id: 7, name: 'Familia Gómez'),
        members: [_member(1, 'Tomás', 'Gómez')],
      );

      expect(detail.matches('familia'), isTrue);
      expect(detail.matches('tomas'), isTrue);
      expect(detail.matches('acosta'), isFalse);
    });

    test('sorts by its first member and leaves empty groups last', () {
      final empty = groupOf([]);
      final acosta = groupOf([_member(1, 'Sofía', 'Acosta')]);
      final gomez = groupOf([_member(2, 'Laura', 'Gómez')]);

      expect(
        ([gomez, empty, acosta]..sort(FamilyGroupDetail.byFirstMember)),
        [acosta, gomez, empty],
      );
    });
  });
}
