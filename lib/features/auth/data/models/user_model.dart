import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
  });

  static const String _memberRole = 'MEMBER';
  static const String _adminRole = 'ADMIN';
  static const String _superAdminRole = 'SUPER_ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: _roleFromJson(json['role'] as String?),
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
    );
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
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': _roleToJson(role),
    };
  }
}
