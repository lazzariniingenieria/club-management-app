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
        MemberCollectionFilter.fromQueryValue('inactive'),
        MemberCollectionFilter.all,
      );
    });
  });

  group('matching', () {
    test('all keeps active and inactive members alike', () {
      const filter = MemberCollectionFilter.all;

      expect(filter.matches(buildMember(), const {}), isTrue);
      expect(
        filter.matches(buildMember(status: MemberStatus.inactive), const {}),
        isTrue,
      );
    });

    test('overdue keeps only members behind on the fee', () {
      const filter = MemberCollectionFilter.overdue;

      expect(filter.matches(buildMember(daysOverdue: 12), const {}), isTrue);
      expect(filter.matches(buildMember(), const {}), isFalse);
    });

    test('toCollect keeps only the members marked for the report', () {
      const filter = MemberCollectionFilter.toCollect;

      expect(filter.matches(buildMember(id: 7), const {7}), isTrue);
      expect(filter.matches(buildMember(id: 8), const {7}), isFalse);
    });
  });
}
