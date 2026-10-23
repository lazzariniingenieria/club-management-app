import 'package:club_management_app/features/family_groups/domain/entities/family_group.dart';
import 'package:club_management_app/features/family_groups/presentation/formatting/family_group_formats.dart';
import 'package:club_management_app/features/members/data/models/member_model.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:flutter_test/flutter_test.dart';

MemberModel _member(String first, String last) => MemberModel(
      id: first.hashCode,
      firstName: first,
      lastName: last,
      dni: '30111222',
      status: MemberStatus.active,
      daysOverdue: 0,
    );

void main() {
  test('falls back to "Grupo familiar" without a name', () {
    expect(FamilyGroupFormats.displayName(null), 'Grupo familiar');
    expect(
      FamilyGroupFormats.displayName(const FamilyGroup(id: 1)),
      'Grupo familiar',
    );
    expect(
      FamilyGroupFormats.displayName(const FamilyGroup(id: 1, name: ' Torres ')),
      'Torres',
    );
  });

  test('summarises the relatives without filling the card', () {
    final laura = _member('Laura', 'Gómez');
    final tomas = _member('Tomás', 'Gómez');
    final ana = _member('Ana', 'Gómez');
    final juan = _member('Juan', 'Gómez');

    expect(FamilyGroupFormats.relatives([laura]), 'Con Laura Gómez');
    expect(
      FamilyGroupFormats.relatives([laura, tomas]),
      'Con Laura Gómez y Tomás Gómez',
    );
    expect(
      FamilyGroupFormats.relatives([laura, tomas, ana, juan]),
      'Con Laura Gómez, Tomás Gómez y 2 más',
    );
  });

  test('lists names with commas and a final "y"', () {
    final laura = _member('Laura', 'Gómez');
    final tomas = _member('Tomás', 'Gómez');
    final ana = _member('Ana', 'Gómez');

    expect(FamilyGroupFormats.namesList([laura]), 'Laura Gómez');
    expect(
      FamilyGroupFormats.namesList([laura, tomas]),
      'Laura Gómez y Tomás Gómez',
    );
    expect(
      FamilyGroupFormats.namesList([laura, tomas, ana]),
      'Laura Gómez, Tomás Gómez y Ana Gómez',
    );
  });

  test('suggests a name from the member surname', () {
    expect(
      FamilyGroupFormats.defaultName(_member('Marcos', 'Gómez')),
      'Familia Gómez',
    );
  });
}
