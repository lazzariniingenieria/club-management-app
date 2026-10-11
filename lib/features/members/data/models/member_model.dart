import '../../domain/entities/member.dart';

class MemberModel extends Member {
  const MemberModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.dni,
    required super.status,
    required super.daysOverdue,
  });

  static const String _idKey = 'id';
  static const String _firstNameKey = 'firstName';
  static const String _lastNameKey = 'lastName';
  static const String _dniKey = 'dni';
  static const String _statusKey = 'status';
  static const String _memberIdKey = 'memberId';
  static const String _daysOverdueKey = 'daysOverdue';
  static const String _activeStatus = 'ACTIVE';

  static List<MemberModel> listFromResponses({
    required List<dynamic> members,
    required List<dynamic> delinquency,
  }) {
    final daysOverdueByMemberId = _daysOverdueByMemberId(delinquency);

    return [
      for (final member in members)
        _fromRow(member as Map<String, dynamic>, daysOverdueByMemberId),
    ];
  }

  static MemberModel _fromRow(
    Map<String, dynamic> row,
    Map<int, int> daysOverdueByMemberId,
  ) {
    final id = (row[_idKey] as num).toInt();

    return MemberModel(
      id: id,
      firstName: row[_firstNameKey] as String,
      lastName: row[_lastNameKey] as String,
      dni: row[_dniKey] as String,
      status: _statusFrom(row[_statusKey] as String?),
      daysOverdue: daysOverdueByMemberId[id] ?? 0,
    );
  }

  static Map<int, int> _daysOverdueByMemberId(List<dynamic> delinquency) {
    return {
      for (final row in delinquency.cast<Map<String, dynamic>>())
        (row[_memberIdKey] as num).toInt():
            (row[_daysOverdueKey] as num).toInt(),
    };
  }

  static MemberStatus _statusFrom(String? status) {
    return status?.toUpperCase() == _activeStatus
        ? MemberStatus.active
        : MemberStatus.inactive;
  }
}
