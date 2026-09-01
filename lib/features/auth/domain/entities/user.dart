import 'package:equatable/equatable.dart';

enum UserRole { member, admin, superAdmin }

extension UserRolePermissions on UserRole {
  bool get canManageAdmins => this == UserRole.superAdmin;

  bool get usesAdminSurface =>
      this == UserRole.admin || this == UserRole.superAdmin;
}

class User extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  @override
  List<Object?> get props => [id, email, fullName, role];
}
