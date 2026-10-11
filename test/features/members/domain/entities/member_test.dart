import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:flutter_test/flutter_test.dart';

Member buildMember({
  String firstName = 'Juan',
  String lastName = 'Pérez',
  String dni = '30111222',
  MemberStatus status = MemberStatus.active,
  int daysOverdue = 0,
}) {
  return Member(
    id: 1,
    firstName: firstName,
    lastName: lastName,
    dni: dni,
    status: status,
    daysOverdue: daysOverdue,
  );
}

void main() {
  group('payment standing', () {
    test('a member with no overdue days is up to date', () {
      expect(buildMember().isOverdue, isFalse);
    });

    test('a member with overdue days is behind on the fee', () {
      expect(buildMember(daysOverdue: 12).isOverdue, isTrue);
    });

    test('the two status axes stay independent', () {
      final member = buildMember(status: MemberStatus.active, daysOverdue: 40);

      expect(member.isActive, isTrue);
      expect(member.isOverdue, isTrue);
    });
  });

  group('search', () {
    test('an empty query matches every member', () {
      expect(buildMember().matches('   '), isTrue);
    });

    test('matches on part of the name regardless of case', () {
      expect(buildMember(firstName: 'Juan').matches('JUA'), isTrue);
    });

    test('matches on the dni', () {
      expect(buildMember(dni: '30111222').matches('1112'), isTrue);
    });

    test('matches an accented name typed without accents', () {
      expect(buildMember(lastName: 'Álvarez').matches('alvarez'), isTrue);
    });

    test('does not match an unrelated query', () {
      expect(buildMember(firstName: 'Juan').matches('Romero'), isFalse);
    });
  });

  group('sorting', () {
    test('orders by last name ignoring accents', () {
      final keys = [
        buildMember(lastName: 'Zárate').sortKey,
        buildMember(lastName: 'Álvarez').sortKey,
        buildMember(lastName: 'Gómez').sortKey,
      ]..sort();

      expect(keys.first, startsWith('alvarez'));
      expect(keys.last, startsWith('zarate'));
    });

    test('falls back to the first name within the same last name', () {
      final ana = buildMember(firstName: 'Ana', lastName: 'Gómez').sortKey;
      final luis = buildMember(firstName: 'Luis', lastName: 'Gómez').sortKey;

      expect(ana.compareTo(luis), isNegative);
    });
  });

  test('exposes the full name for the list row', () {
    expect(
        buildMember(firstName: 'Ana', lastName: 'Gómez').fullName, 'Ana Gómez');
  });
}
