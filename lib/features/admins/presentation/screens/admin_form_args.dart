import '../../../members/domain/entities/member.dart';
import '../../domain/entities/admin.dart';

class AdminFormArgs {
  final Admin? admin;
  final List<Member> members;

  const AdminFormArgs({required this.members, this.admin});
}
