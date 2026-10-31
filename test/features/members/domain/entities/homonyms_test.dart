import 'package:club_management_app/features/members/domain/entities/homonyms.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:flutter_test/flutter_test.dart';

Member member(int id, String firstName, String lastName) => Member(
      id: id,
      firstName: firstName,
      lastName: lastName,
      dni: '${30000000 + id}',
      status: MemberStatus.active,
      daysOverdue: 0,
    );

void main() {
  test('flags every member who shares first and last name with another', () {
    final first = member(1, 'Juan', 'Pérez');
    final second = member(2, 'Juan', 'Pérez');
    final homonyms = Homonyms.among([first, second, member(3, 'Ana', 'Pérez')]);

    expect(homonyms.includes(first), isTrue);
    expect(homonyms.includes(second), isTrue);
  });

  test('leaves alone a member whose name is unique', () {
    final unique = member(3, 'Ana', 'Pérez');
    final homonyms = Homonyms.among([member(1, 'Juan', 'Pérez'), unique]);

    expect(homonyms.includes(unique), isFalse);
  });

  test('ignores accents and case, as a person reading the list would', () {
    final accented = member(1, 'José', 'Gómez');
    final plain = member(2, 'jose', 'gomez');

    expect(Homonyms.among([accented, plain]).includes(accented), isTrue);
  });
}
