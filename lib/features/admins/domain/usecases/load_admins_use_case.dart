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
        (roster) => AdminsOverview(admins: _sorted(adminList), members: roster),
      ),
    );
  }

  static List<Admin> _sorted(List<Admin> admins) {
    return [...admins]..sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;

        return a.dni.compareTo(b.dni);
      });
  }
}
