import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/members/data/datasources/member_remote_data_source.dart';
import 'package:club_management_app/features/members/data/models/member_model.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/entities/member_draft.dart';

mixin _ReadOnlyMemberSource implements MemberRemoteDataSource {
  @override
  Future<void> createMember(MemberDraft draft) => _unsupported();

  @override
  Future<void> updateMember(int memberId, MemberDraft draft) => _unsupported();

  @override
  Future<void> setMemberActive(int memberId, {required bool isActive}) =>
      _unsupported();

  Future<void> _unsupported() =>
      throw UnsupportedError('This test source only serves reads');
}

class MemberRosterDataSource with _ReadOnlyMemberSource {
  MemberRosterDataSource(this.roster);

  final List<MemberModel> roster;

  @override
  Future<List<MemberModel>> fetchMembers() async => roster;
}

class FailingMemberDataSource with _ReadOnlyMemberSource {
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
  String? phone,
}) {
  return MemberModel(
    id: id,
    firstName: firstName,
    lastName: lastName,
    dni: dni ?? '${30000000 + id}',
    status: status,
    daysOverdue: daysOverdue,
    phone: phone,
  );
}

class FlakyMemberDataSource with _ReadOnlyMemberSource {
  FlakyMemberDataSource(this.roster);

  final List<MemberModel> roster;
  bool failsNext = false;

  @override
  Future<List<MemberModel>> fetchMembers() async {
    if (failsNext) throw NetworkException('offline');

    return roster;
  }
}
