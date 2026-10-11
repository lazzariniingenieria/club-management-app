import 'package:club_management_app/features/admin/data/datasources/admin_summary_fake_data_source.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
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
}
