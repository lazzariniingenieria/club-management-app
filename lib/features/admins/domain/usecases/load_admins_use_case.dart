import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../entities/admin.dart';
import '../entities/admins_overview.dart';
import '../repositories/admin_repository.dart';

class LoadAdminsUseCase {
  final AdminRepository admins;
  final MemberRepository members;

  LoadAdminsUseCase({required this.admins, required this.members});

  Future<Either<Failure, AdminsOverview>> call() async {
    final results = await Future.wait<Object>([
      admins.loadAdmins(),
      members.loadMembers(),
    ]);
    final adminList = results[0] as Either<Failure, List<Admin>>;
    final roster = results[1] as Either<Failure, List<Member>>;

    return adminList.flatMap(
      (adminList) => roster.map(
        (roster) => AdminsOverview(
          admins: _sorted(adminList, roster),
          members: roster,
        ),
      ),
    );
  }

  static List<Admin> _sorted(List<Admin> admins, List<Member> roster) {
    final membersById = {for (final member in roster) member.id: member};

    return [...admins]..sort((a, b) => _compare(a, b, membersById));
  }

  static int _compare(Admin a, Admin b, Map<int, Member> membersById) {
    if (a.isActive != b.isActive) return a.isActive ? -1 : 1;

    final first = membersById[a.memberId];
    final second = membersById[b.memberId];
    if (first != null && second != null) {
      return first.sortKey.compareTo(second.sortKey);
    }
    if (first != null || second != null) return first != null ? -1 : 1;

    return _compareDni(a.dni, b.dni);
  }

  static int _compareDni(String a, String b) =>
      a.length != b.length ? a.length.compareTo(b.length) : a.compareTo(b);
}
