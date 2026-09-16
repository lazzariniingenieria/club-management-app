import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: (json['role'] as String).toUpperCase() == 'ADMIN'
          ? UserRole.admin
          : UserRole.member,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role == UserRole.admin ? 'ADMIN' : 'MEMBER',
    };
  }
}
