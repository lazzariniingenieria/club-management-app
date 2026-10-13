import 'package:equatable/equatable.dart';

import 'member.dart';

class MemberDraft extends Equatable {
  final String firstName;
  final String lastName;
  final String dni;
  final String phone;
  final String email;

  const MemberDraft({
    required this.firstName,
    required this.lastName,
    required this.dni,
    this.phone = '',
    this.email = '',
  });

  factory MemberDraft.fromMember(Member member) {
    return MemberDraft(
      firstName: member.firstName,
      lastName: member.lastName,
      dni: member.dni,
      phone: member.phone ?? '',
      email: member.email ?? '',
    );
  }

  MemberDraft trimmed() {
    return MemberDraft(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      dni: dni.trim(),
      phone: phone.trim(),
      email: email.trim(),
    );
  }

  @override
  List<Object?> get props => [firstName, lastName, dni, phone, email];
}
