import 'package:club_management_app/features/members/data/datasources/member_remote_data_source.dart';
import 'package:club_management_app/features/members/data/models/member_model.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';

class MemberRosterDataSource implements MemberRemoteDataSource {
  MemberRosterDataSource(this.roster);

  final List<MemberModel> roster;
  int calls = 0;

  @override
  Future<List<MemberModel>> fetchMembers() async {
    calls++;

    return roster;
  }
}

class FailingMemberDataSource implements MemberRemoteDataSource {
  FailingMemberDataSource(this.error);

  final Object error;

  @override
  Future<List<MemberModel>> fetchMembers() async => throw error;
}

MemberModel buildMember({
  required int id,
  String firstName = 'Juan',
  String lastName = 'Pérez',
  String? dni,
  MemberStatus status = MemberStatus.active,
  int daysOverdue = 0,
}) {
  return MemberModel(
    id: id,
    firstName: firstName,
    lastName: lastName,
    dni: dni ?? '${30000000 + id}',
    status: status,
    daysOverdue: daysOverdue,
  );
}
