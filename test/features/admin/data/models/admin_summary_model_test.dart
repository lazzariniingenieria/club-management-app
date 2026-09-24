import 'package:club_management_app/features/admin/data/models/admin_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const members = [
    {'id': 1, 'status': 'ACTIVE'},
    {'id': 2, 'status': 'ACTIVE'},
    {'id': 3, 'status': 'INACTIVE'},
  ];

  const delinquency = [
    {'memberId': 1, 'daysOverdue': 21},
    {'memberId': 2, 'daysOverdue': 0},
  ];

  test('counts only the members the club still considers active', () {
    final summary = AdminSummaryModel.fromResponses(
      members: members,
      delinquency: delinquency,
    );

    expect(summary.activeMembers, 2);
  });

  test('reads a member as overdue only when the API reports days owed', () {
    final summary = AdminSummaryModel.fromResponses(
      members: members,
      delinquency: delinquency,
    );

    expect(summary.overdueMembers, 1);
  });

  test('a club with no members reports zeros instead of failing', () {
    final summary = AdminSummaryModel.fromResponses(
      members: const [],
      delinquency: const [],
    );

    expect(summary.activeMembers, 0);
    expect(summary.overdueMembers, 0);
  });

  test('the two counters are independent: an active member can be overdue', () {
    final summary = AdminSummaryModel.fromResponses(
      members: const [
        {'id': 1, 'status': 'ACTIVE'},
      ],
      delinquency: const [
        {'memberId': 1, 'daysOverdue': 45},
      ],
    );

    expect(summary.activeMembers, 1);
    expect(summary.overdueMembers, 1);
  });
}
