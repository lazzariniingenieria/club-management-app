import 'package:equatable/equatable.dart';

class Admin extends Equatable {
  final int id;
  final String dni;
  final String? email;
  final int? memberId;
  final bool isActive;

  const Admin({
    required this.id,
    required this.dni,
    required this.isActive,
    this.email,
    this.memberId,
  });

  bool get isLinkedToMember => memberId != null;

  @override
  List<Object?> get props => [id, dni, email, memberId, isActive];
}
