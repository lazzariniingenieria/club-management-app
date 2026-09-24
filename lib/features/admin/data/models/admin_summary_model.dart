import '../../domain/entities/admin_summary.dart';

class AdminSummaryModel extends AdminSummary {
  const AdminSummaryModel({
    required super.activeMembers,
    required super.overdueMembers,
  });

  static const String _statusKey = 'status';
  static const String _activeStatus = 'ACTIVE';
  static const String _daysOverdueKey = 'daysOverdue';

  factory AdminSummaryModel.fromResponses({
    required List<dynamic> members,
    required List<dynamic> delinquency,
  }) {
    return AdminSummaryModel(
      activeMembers: _countActiveMembers(members),
      overdueMembers: _countOverdueMembers(delinquency),
    );
  }

  static int _countActiveMembers(List<dynamic> members) {
    var activeMembers = 0;

    for (final member in members) {
      final status = (member as Map<String, dynamic>)[_statusKey] as String?;
      if (status?.toUpperCase() == _activeStatus) activeMembers++;
    }

    return activeMembers;
  }

  static int _countOverdueMembers(List<dynamic> delinquency) {
    var overdueMembers = 0;

    for (final member in delinquency) {
      final row = member as Map<String, dynamic>;
      final daysOverdue = (row[_daysOverdueKey] as num).toInt();
      if (daysOverdue > 0) overdueMembers++;
    }

    return overdueMembers;
  }
}
