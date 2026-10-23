import 'package:equatable/equatable.dart';

import '../../../members/domain/entities/member.dart';
import 'admin.dart';

class AdminsOverview extends Equatable {
  final List<Admin> admins;
  final List<Member> members;

  const AdminsOverview({required this.admins, required this.members});

  Member? memberOf(Admin admin) {
    for (final member in members) {
      if (member.id == admin.memberId) return member;
    }

    return null;
  }

  Set<int> memberIdsTakenBesides(Admin? edited) => {
        for (final admin in admins)
          if (admin.memberId != null && admin.id != edited?.id) admin.memberId!,
      };

  @override
  List<Object?> get props => [admins, members];
}
