import 'package:equatable/equatable.dart';

import 'admin.dart';

class AdminDraft extends Equatable {
  final String dni;
  final String email;
  final int? memberId;

  const AdminDraft({required this.dni, this.email = '', this.memberId});

  factory AdminDraft.fromAdmin(Admin admin) => AdminDraft(
        dni: admin.dni,
        email: admin.email ?? '',
        memberId: admin.memberId,
      );

  AdminDraft trimmed() =>
      AdminDraft(dni: dni.trim(), email: email.trim(), memberId: memberId);

  @override
  List<Object?> get props => [dni, email, memberId];
}
