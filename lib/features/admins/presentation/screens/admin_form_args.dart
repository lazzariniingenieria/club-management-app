import '../../../members/domain/entities/member.dart';
import '../../domain/entities/admin.dart';
import '../../domain/entities/admins_overview.dart';

class AdminFormArgs {
  final Admin? admin;
  final List<Member> members;
  final Set<int> takenMemberIds;

  const AdminFormArgs({
    required this.members,
    this.admin,
    this.takenMemberIds = const {},
  });

  factory AdminFormArgs.from(AdminsOverview overview, {Admin? admin}) =>
      AdminFormArgs(
        members: overview.members,
        admin: admin,
        takenMemberIds: overview.memberIdsTakenBesides(admin),
      );
}
