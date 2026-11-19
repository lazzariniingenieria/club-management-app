import 'package:equatable/equatable.dart';

enum MemberAccountRole { member, admin }

class MemberAccount extends Equatable {
  final int id;
  final int memberId;
  final String dni;
  final MemberAccountRole role;
  final bool isActive;

  const MemberAccount({
    required this.id,
    required this.memberId,
    required this.dni,
    required this.role,
    required this.isActive,
  });

  bool get canResetPassword => role == MemberAccountRole.member;

  @override
  List<Object?> get props => [id, memberId, dni, role, isActive];
}
