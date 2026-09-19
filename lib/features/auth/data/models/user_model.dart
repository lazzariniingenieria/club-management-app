import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.memberId,
    required super.role,
  });

  static const String _memberRole = 'MEMBER';
  static const String _adminRole = 'ADMIN';
  static const String _superAdminRole = 'SUPER_ADMIN';

  static const String _idKey = 'userAccountId';
  static const String _memberIdKey = 'memberId';
  static const String _roleKey = 'role';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json[_idKey] as num).toInt(),
      memberId: (json[_memberIdKey] as num?)?.toInt(),
      role: _roleFromJson(json[_roleKey] as String?),
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(id: user.id, memberId: user.memberId, role: user.role);
  }

  static UserRole _roleFromJson(String? role) {
    return switch (role?.toUpperCase()) {
      _superAdminRole => UserRole.superAdmin,
      _adminRole => UserRole.admin,
      _ => UserRole.member,
    };
  }

  static String _roleToJson(UserRole role) {
    return switch (role) {
      UserRole.superAdmin => _superAdminRole,
      UserRole.admin => _adminRole,
      UserRole.member => _memberRole,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      _idKey: id,
      _memberIdKey: memberId,
      _roleKey: _roleToJson(role),
    };
  }
}
