import '../../domain/entities/member_account.dart';

class MemberAccountModel extends MemberAccount {
  const MemberAccountModel({
    required super.id,
    required super.memberId,
    required super.dni,
    required super.role,
    required super.isActive,
  });

  static const String _idKey = 'id';
  static const String _memberIdKey = 'memberId';
  static const String _dniKey = 'dni';
  static const String _roleKey = 'role';
  static const String _activeKey = 'active';
  static const String _passwordKey = 'password';
  static const String _newPasswordKey = 'newPassword';
  static const String _memberRole = 'MEMBER';

  factory MemberAccountModel.fromJson(Map<String, dynamic> json) {
    return MemberAccountModel(
      id: (json[_idKey] as num).toInt(),
      memberId: (json[_memberIdKey] as num).toInt(),
      dni: json[_dniKey] as String,
      role: _roleFromJson(json[_roleKey] as String),
      isActive: json[_activeKey] as bool,
    );
  }

  static MemberAccountRole _roleFromJson(String role) {
    return role == _memberRole
        ? MemberAccountRole.member
        : MemberAccountRole.admin;
  }

  static Map<String, dynamic> bodyForCreate(String password) =>
      {_passwordKey: password};

  static Map<String, dynamic> bodyForReset(String newPassword) =>
      {_newPasswordKey: newPassword};
}
