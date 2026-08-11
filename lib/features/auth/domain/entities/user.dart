import 'package:equatable/equatable.dart';

enum UserRole { member, admin }

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
