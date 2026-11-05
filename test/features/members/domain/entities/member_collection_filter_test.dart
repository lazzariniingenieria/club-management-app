import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/entities/member_collection_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Member buildMember({
  int id = 1,
  MemberStatus status = MemberStatus.active,
  int daysOverdue = 0,
}) {
  return Member(
    id: id,
    firstName: 'Juan',
    lastName: 'Pérez',
    dni: '30111222',
    status: status,
    daysOverdue: daysOverdue,
  );
}

void main() {
  group('query values', () {
    test('maps every filter back from its query value', () {
      for (final filter in MemberCollectionFilter.values) {
        expect(
          MemberCollectionFilter.fromQueryValue(filter.queryValue),
          filter,
        );
      }
    });

    test('falls back to all for a missing or unknown value', () {
      expect(
        MemberCollectionFilter.fromQueryValue(null),
        MemberCollectionFilter.all,
      );
      expect(
        MemberCollectionFilter.fromQueryValue('active'),
        MemberCollectionFilter.all,
      );
    });

    test('a link to the retired a cobrar chip opens every member', () {
      expect(
        MemberCollectionFilter.fromQueryValue('to-collect'),
        MemberCollectionFilter.all,
      );
    });
  });

  group('matching', () {
    test('all keeps only the members still in the club, as the home counts',
        () {
      const filter = MemberCollectionFilter.all;

      expect(filter.matches(buildMember()), isTrue);
      expect(
        filter.matches(buildMember(status: MemberStatus.inactive)),
        isFalse,
      );
    });

    test('inactive keeps only the members who were let go', () {
      const filter = MemberCollectionFilter.inactive;

      expect(filter.matches(buildMember(status: MemberStatus.inactive)), isTrue);
      expect(filter.matches(buildMember()), isFalse);
    });

    test('overdue keeps only members behind on the fee', () {
      const filter = MemberCollectionFilter.overdue;

      expect(filter.matches(buildMember(daysOverdue: 12)), isTrue);
      expect(filter.matches(buildMember()), isFalse);
    });

    test('overdue leaves out an inactive member, whose fee no longer counts',
        () {
      expect(
        MemberCollectionFilter.overdue.matches(
          buildMember(status: MemberStatus.inactive, daysOverdue: 12),
        ),
        isFalse,
      );
    });
  });
}
