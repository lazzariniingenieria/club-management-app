import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/admin_draft.dart';
import '../models/admin_model.dart';
import 'admin_remote_data_source.dart';
import 'fake_user_account_store.dart';

class AdminFakeDataSource implements AdminRemoteDataSource {
  AdminFakeDataSource({
    this.latency = const Duration(milliseconds: 600),
    FakeUserAccountStore? accounts,
  }) : accounts = accounts ?? FakeUserAccountStore();

  final Duration latency;
  final FakeUserAccountStore accounts;

  @override
  Future<List<AdminModel>> fetchAdmins() async {
    await Future<void>.delayed(latency);

    return [for (final account in accounts.admins) _toModel(account)];
  }

  @override
  Future<void> createAdmin(AdminDraft draft, String password) async {
    await Future<void>.delayed(latency);
    _rejectTaken(draft);

    accounts.save(_fromDraft(accounts.nextId(), draft, isActive: true));
  }

  @override
  Future<void> updateAdmin(int adminId, AdminDraft draft) async {
    await Future<void>.delayed(latency);
    final current = _adminOf(adminId);
    _rejectTaken(draft, keeping: adminId);

    accounts.save(_fromDraft(adminId, draft, isActive: current.isActive));
  }

  @override
  Future<void> setAdminActive(int adminId, {required bool isActive}) async {
    await Future<void>.delayed(latency);
    final current = _adminOf(adminId);
    final becomesMember = !isActive && current.memberId != null;

    accounts.save(
      becomesMember
          ? current.withRole(FakeAccountRole.member, isActive: true)
          : current.withRole(FakeAccountRole.admin, isActive: isActive),
    );
  }

  @override
  Future<void> promoteMember(int memberId) async {
    await Future<void>.delayed(latency);
    final account = accounts.ofMember(memberId);
    if (account == null || account.isAdmin) {
      throw NotFoundException('member $memberId has no member account');
    }

    accounts.save(account.withRole(FakeAccountRole.admin, isActive: true));
  }

  @override
  Future<void> resetPassword(int adminId, String newPassword) async {
    await Future<void>.delayed(latency);
    _adminOf(adminId);
  }

  @override
  Future<void> changeOwnPassword(String newPassword) async {
    await Future<void>.delayed(latency);
  }

  static AdminModel _toModel(FakeUserAccount account) {
    return AdminModel(
      id: account.id,
      dni: account.dni,
      email: account.email,
      memberId: account.memberId,
      isActive: account.isActive,
    );
  }

  static FakeUserAccount _fromDraft(
    int id,
    AdminDraft draft, {
    required bool isActive,
  }) {
    return FakeUserAccount(
      id: id,
      dni: draft.dni,
      email: draft.email.isEmpty ? null : draft.email,
      memberId: draft.memberId,
      role: FakeAccountRole.admin,
      isActive: isActive,
    );
  }

  void _rejectTaken(AdminDraft draft, {int? keeping}) {
    for (final account in accounts.all.where((a) => a.id != keeping)) {
      final memberTaken =
          draft.memberId != null && account.memberId == draft.memberId;
      if (account.dni == draft.dni || memberTaken) {
        throw ConflictException('DNI or member already in use');
      }
    }
  }

  FakeUserAccount _adminOf(int adminId) {
    final account = accounts.byId(adminId);
    if (account == null || !account.isAdmin) {
      throw NotFoundException('Unknown admin $adminId');
    }

    return account;
  }
}
