import '../../../../core/errors/exceptions.dart';
import '../../../admins/data/datasources/admin_remote_data_source.dart';
import '../../../admins/data/models/admin_model.dart';
import '../../../club/data/datasources/club_remote_data_source.dart';
import '../../../members/data/datasources/member_remote_data_source.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/member_account.dart';
import '../models/member_account_model.dart';
import 'member_account_remote_data_source.dart';

class MemberAccountFakeDataSource implements MemberAccountRemoteDataSource {
  MemberAccountFakeDataSource({
    required MemberRemoteDataSource members,
    required AdminRemoteDataSource admins,
    required ClubRemoteDataSource club,
    this.latency = const Duration(milliseconds: 600),
  })  : _members = members,
        _admins = admins,
        _club = club,
        _memberAccounts = [...seeded];

  final MemberRemoteDataSource _members;
  final AdminRemoteDataSource _admins;
  final ClubRemoteDataSource _club;
  final Duration latency;
  final List<MemberAccountModel> _memberAccounts;

  static const List<MemberAccountModel> seeded = [
    MemberAccountModel(
      id: 40,
      memberId: 2,
      dni: '20013577',
      role: MemberAccountRole.member,
      isActive: true,
    ),
  ];

  @override
  Future<MemberAccountModel?> fetchAccount(int memberId) async {
    await Future<void>.delayed(latency);
    await _members.fetchMember(memberId);

    return _accountOf(memberId, await _admins.fetchAdmins());
  }

  @override
  Future<MemberAccountModel> createAccount(
      int memberId, String password) async {
    await Future<void>.delayed(latency);
    await _rejectDisabledMemberApp();
    final dni = _dniOfEligible(await _members.fetchMember(memberId));
    final admins = await _admins.fetchAdmins();
    _rejectTaken(memberId, dni, admins);

    final account = MemberAccountModel(
      id: _nextId(admins),
      memberId: memberId,
      dni: dni,
      role: MemberAccountRole.member,
      isActive: true,
    );
    _memberAccounts.add(account);

    return account;
  }

  @override
  Future<MemberAccountModel> resetPassword(
    int memberId,
    String newPassword,
  ) async {
    await Future<void>.delayed(latency);
    await _members.fetchMember(memberId);

    return _memberAccounts.firstWhere(
      (account) => account.memberId == memberId,
      orElse: () =>
          throw NotFoundException('member $memberId has no member account'),
    );
  }

  Future<void> _rejectDisabledMemberApp() async {
    final club = await _club.fetchClub();
    if (!club.memberAppEnabled) {
      throw ValidationException('member app is not enabled for this club');
    }
  }

  static String _dniOfEligible(Member member) {
    if (!member.isActive) {
      throw ValidationException('member ${member.id} is inactive');
    }
    final dni = member.dni;
    if (dni == null) {
      throw ValidationException('member ${member.id} has no dni');
    }

    return dni;
  }

  void _rejectTaken(int memberId, String dni, List<AdminModel> admins) {
    if (_accountOf(memberId, admins) != null) {
      throw ConflictException('member $memberId already has an account');
    }
    final dnis = [
      ...admins.map((admin) => admin.dni),
      ..._memberAccounts.map((account) => account.dni),
    ];
    if (dnis.contains(dni)) {
      throw ConflictException('dni $dni is already in use in this club');
    }
  }

  MemberAccountModel? _accountOf(int memberId, List<AdminModel> admins) {
    for (final admin in admins) {
      if (admin.memberId == memberId) return _adminAccount(admin, memberId);
    }

    return _memberAccounts
        .where((account) => account.memberId == memberId)
        .firstOrNull;
  }

  static MemberAccountModel _adminAccount(AdminModel admin, int memberId) {
    return MemberAccountModel(
      id: admin.id,
      memberId: memberId,
      dni: admin.dni,
      role: MemberAccountRole.admin,
      isActive: admin.isActive,
    );
  }

  int _nextId(List<AdminModel> admins) {
    var highestId = 0;
    final ids = [
      ...admins.map((admin) => admin.id),
      ..._memberAccounts.map((account) => account.id),
    ];

    for (final id in ids) {
      if (id > highestId) highestId = id;
    }

    return highestId + 1;
  }
}
