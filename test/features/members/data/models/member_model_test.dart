import 'package:club_management_app/features/members/data/models/member_model.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:flutter_test/flutter_test.dart';

const List<dynamic> _members = [
  {
    'id': 1,
    'firstName': 'Juan',
    'lastName': 'Pérez',
    'dni': '30111222',
    'status': 'ACTIVE',
  },
  {
    'id': 2,
    'firstName': 'Ana',
    'lastName': 'Gómez',
    'dni': '28999111',
    'status': 'ACTIVE',
  },
  {
    'id': 3,
    'firstName': 'Luis',
    'lastName': 'Romero',
    'dni': '31444555',
    'status': 'INACTIVE',
  },
];

const List<dynamic> _delinquency = [
  {'memberId': 1, 'daysOverdue': 42},
  {'memberId': 2, 'daysOverdue': 0},
];

void main() {
  List<MemberModel> mapRoster() {
    return MemberModel.listFromResponses(
      members: _members,
      delinquency: _delinquency,
    );
  }

  test('keeps one domain member per row of the member endpoint', () {
    expect(mapRoster(), hasLength(_members.length));
  });

  test('joins the delinquency rows by member id', () {
    final roster = mapRoster();

    expect(roster.first.daysOverdue, 42);
    expect(roster.first.isOverdue, isTrue);
    expect(roster[1].daysOverdue, 0);
    expect(roster[1].isOverdue, isFalse);
  });

  test('treats a member missing from the delinquency list as up to date', () {
    final inactiveMember = mapRoster().last;

    expect(inactiveMember.daysOverdue, 0);
    expect(inactiveMember.isOverdue, isFalse);
  });

  test('maps the member status enum', () {
    final roster = mapRoster();

    expect(roster.first.status, MemberStatus.active);
    expect(roster.last.status, MemberStatus.inactive);
  });

  test('reads numeric ids coming from the Java Long serialization', () {
    expect(mapRoster().first.id, 1);
  });

  test('keeps the identity fields the list row renders', () {
    final member = mapRoster().first;

    expect(member.fullName, 'Juan Pérez');
    expect(member.dni, '30111222');
  });

  test('maps an empty club to an empty roster', () {
    final roster = MemberModel.listFromResponses(
      members: const [],
      delinquency: const [],
    );

    expect(roster, isEmpty);
  });
}
