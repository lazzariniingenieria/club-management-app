import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/admin/data/datasources/admin_summary_fake_data_source.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/entities/member_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final roster = MemberFakeDataSource.roster;

  int countWhere(bool Function(Member member) test) =>
      roster.where(test).length;

  test('seeds a club small enough to scroll end to end while developing', () {
    expect(roster, hasLength(MemberFakeDataSource.totalMembers));
    expect(MemberFakeDataSource.totalMembers, lessThan(60));
  });

  test('splits the roster across both status axes', () {
    expect(
      countWhere((member) => member.isActive),
      MemberFakeDataSource.activeMembers,
    );
    expect(
      countWhere((member) => !member.isActive),
      MemberFakeDataSource.inactiveMembers,
    );
    expect(
      countWhere((member) => member.isOverdue),
      MemberFakeDataSource.overdueMembers,
    );
  });

  test('never marks an inactive member as overdue', () {
    expect(countWhere((member) => !member.isActive && member.isOverdue), 0);
  });

  test('gives every seeded member a distinct name and dni', () {
    expect(
        roster.map((member) => member.dni).toSet(), hasLength(roster.length));
    expect(
      roster.map((member) => member.fullName).toSet(),
      hasLength(roster.length),
    );
  });

  test('keeps the home counters and the roster telling the same story', () {
    const summary = AdminSummaryFakeDataSource.summary;

    expect(summary.activeMembers, countWhere((member) => member.isActive));
    expect(summary.overdueMembers, countWhere((member) => member.isOverdue));
  });

  group('writes against the in-memory club', () {
    MemberFakeDataSource buildDataSource() =>
        MemberFakeDataSource(latency: Duration.zero);

    const newMember = MemberDraft(
      firstName: 'Ana',
      lastName: 'Nueva',
      dni: '99999999',
    );

    test('a created member joins the club without touching the seed', () async {
      final dataSource = buildDataSource();

      await dataSource.createMember(newMember);

      expect(
        await dataSource.fetchMembers(),
        hasLength(MemberFakeDataSource.totalMembers + 1),
      );
      expect(roster, hasLength(MemberFakeDataSource.totalMembers));
    });

    test('a dni another member already uses is rejected, as the API does', () {
      final dataSource = buildDataSource();

      expect(
        dataSource.createMember(
          MemberDraft(
            firstName: 'Ana',
            lastName: 'Nueva',
            dni: roster.first.dni,
          ),
        ),
        throwsA(isA<ConflictException>()),
      );
    });

    test('the logical delete keeps the member on the roster', () async {
      final dataSource = buildDataSource();
      final target = roster.first;

      await dataSource.setMemberActive(target.id, isActive: false);
      final members = await dataSource.fetchMembers();

      expect(members, hasLength(MemberFakeDataSource.totalMembers));
      expect(
        members.firstWhere((member) => member.id == target.id).isActive,
        isFalse,
      );
    });
  });
}
