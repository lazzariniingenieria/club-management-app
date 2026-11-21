import '../../../../core/errors/exceptions.dart';
import '../../../admins/data/datasources/fake_user_account_store.dart';
import '../../../club/data/datasources/club_remote_data_source.dart';
import '../../../members/data/datasources/member_remote_data_source.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/member_account.dart';
import '../models/member_account_model.dart';
import 'member_account_remote_data_source.dart';

class MemberAccountFakeDataSource implements MemberAccountRemoteDataSource {
  MemberAccountFakeDataSource({
    required MemberRemoteDataSource members,
    required ClubRemoteDataSource club,
    required this.accounts,
    this.latency = const Duration(milliseconds: 600),
  })  : _members = members,
        _club = club;

  final MemberRemoteDataSource _members;
  final ClubRemoteDataSource _club;
  final FakeUserAccountStore accounts;
  final Duration latency;

  @override
  Future<MemberAccountModel?> fetchAccount(int memberId) async {
    await Future<void>.delayed(latency);
    await _members.fetchMember(memberId);

    final account = accounts.ofMember(memberId);

    return account == null ? null : _toModel(account, memberId);
  }

  @override
  Future<MemberAccountModel> createAccount(
      int memberId, String password) async {
    await Future<void>.delayed(latency);
    await _rejectDisabledMemberApp();
    final dni = _dniOfEligible(await _members.fetchMember(memberId));
    _rejectTaken(memberId, dni);

    final account = FakeUserAccount(
      id: accounts.nextId(),
      dni: dni,
      memberId: memberId,
      role: FakeAccountRole.member,
      isActive: true,
    );
    accounts.save(account);

    return _toModel(account, memberId);
  }

  @override
  Future<MemberAccountModel> resetPassword(
    int memberId,
    String newPassword,
  ) async {
    await Future<void>.delayed(latency);
    await _members.fetchMember(memberId);

    final account = accounts.ofMember(memberId);
    if (account == null || account.isAdmin) {
      throw NotFoundException('member $memberId has no member account');
    }

    return _toModel(account, memberId);
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

  void _rejectTaken(int memberId, String dni) {
    if (accounts.ofMember(memberId) != null) {
      throw ConflictException('member $memberId already has an account');
    }
    if (accounts.all.any((account) => account.dni == dni)) {
      throw ConflictException('dni $dni is already in use in this club');
    }
  }

  static MemberAccountModel _toModel(FakeUserAccount account, int memberId) {
    return MemberAccountModel(
      id: account.id,
      memberId: memberId,
      dni: account.dni,
      role:
          account.isAdmin ? MemberAccountRole.admin : MemberAccountRole.member,
      isActive: account.isActive,
    );
  }
}
