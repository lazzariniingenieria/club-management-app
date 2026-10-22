import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/admin_draft.dart';
import '../models/admin_model.dart';
import 'admin_remote_data_source.dart';

class AdminFakeDataSource implements AdminRemoteDataSource {
  AdminFakeDataSource({this.latency = const Duration(milliseconds: 600)})
      : _admins = [...seeded];

  final Duration latency;
  final List<AdminModel> _admins;

  static const List<AdminModel> seeded = [
    AdminModel(id: 2, dni: '11111111', isActive: true),
    AdminModel(
      id: 3,
      dni: '20000000',
      email: 'juan.alvarez@example.com',
      memberId: 1,
      isActive: true,
    ),
    AdminModel(id: 4, dni: '28555666', isActive: false),
  ];

  @override
  Future<List<AdminModel>> fetchAdmins() async {
    await Future<void>.delayed(latency);

    return [..._admins];
  }

  @override
  Future<void> createAdmin(AdminDraft draft, String password) async {
    await Future<void>.delayed(latency);
    _rejectTaken(draft);

    _admins.add(_fromDraft(_nextId(), draft, isActive: true));
  }

  @override
  Future<void> updateAdmin(int adminId, AdminDraft draft) async {
    await Future<void>.delayed(latency);
    _rejectTaken(draft, keeping: adminId);

    final index = _indexOf(adminId);
    _admins[index] =
        _fromDraft(adminId, draft, isActive: _admins[index].isActive);
  }

  @override
  Future<void> setAdminActive(int adminId, {required bool isActive}) async {
    await Future<void>.delayed(latency);
    final current = _admins[_indexOf(adminId)];

    _admins[_indexOf(adminId)] = _fromDraft(
      adminId,
      AdminDraft.fromAdmin(current),
      isActive: isActive,
    );
  }

  @override
  Future<void> resetPassword(int adminId, String newPassword) async {
    await Future<void>.delayed(latency);
    _indexOf(adminId);
  }

  static AdminModel _fromDraft(
    int id,
    AdminDraft draft, {
    required bool isActive,
  }) {
    return AdminModel(
      id: id,
      dni: draft.dni,
      email: draft.email.isEmpty ? null : draft.email,
      memberId: draft.memberId,
      isActive: isActive,
    );
  }

  void _rejectTaken(AdminDraft draft, {int? keeping}) {
    for (final admin in _admins.where((admin) => admin.id != keeping)) {
      final memberTaken =
          draft.memberId != null && admin.memberId == draft.memberId;
      if (admin.dni == draft.dni || memberTaken) {
        throw ConflictException('DNI or member already in use');
      }
    }
  }

  int _indexOf(int adminId) {
    final index = _admins.indexWhere((admin) => admin.id == adminId);
    if (index < 0) throw NotFoundException('Unknown admin $adminId');

    return index;
  }

  int _nextId() {
    var highestId = 0;

    for (final admin in _admins) {
      if (admin.id > highestId) highestId = admin.id;
    }

    return highestId + 1;
  }
}
