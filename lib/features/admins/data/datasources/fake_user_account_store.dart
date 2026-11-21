enum FakeAccountRole { admin, member }

class FakeUserAccount {
  final int id;
  final String dni;
  final String? email;
  final int? memberId;
  final FakeAccountRole role;
  final bool isActive;

  const FakeUserAccount({
    required this.id,
    required this.dni,
    required this.role,
    required this.isActive,
    this.email,
    this.memberId,
  });

  bool get isAdmin => role == FakeAccountRole.admin;

  FakeUserAccount withRole(FakeAccountRole role, {required bool isActive}) {
    return FakeUserAccount(
      id: id,
      dni: dni,
      email: email,
      memberId: memberId,
      role: role,
      isActive: isActive,
    );
  }
}

class FakeUserAccountStore {
  FakeUserAccountStore() : _accounts = [...seeded];

  final List<FakeUserAccount> _accounts;

  static const List<FakeUserAccount> seeded = [
    FakeUserAccount(
      id: 2,
      dni: '11111111',
      role: FakeAccountRole.admin,
      isActive: true,
    ),
    FakeUserAccount(
      id: 3,
      dni: '20000000',
      email: 'juan.alvarez@example.com',
      memberId: 1,
      role: FakeAccountRole.admin,
      isActive: true,
    ),
    FakeUserAccount(
      id: 4,
      dni: '28555666',
      role: FakeAccountRole.admin,
      isActive: false,
    ),
    FakeUserAccount(
      id: 40,
      dni: '20013577',
      memberId: 2,
      role: FakeAccountRole.member,
      isActive: true,
    ),
  ];

  List<FakeUserAccount> get admins =>
      _accounts.where((account) => account.isAdmin).toList();

  List<FakeUserAccount> get all => List.unmodifiable(_accounts);

  FakeUserAccount? byId(int id) =>
      _accounts.where((account) => account.id == id).firstOrNull;

  FakeUserAccount? ofMember(int memberId) =>
      _accounts.where((account) => account.memberId == memberId).firstOrNull;

  void save(FakeUserAccount account) {
    final index = _accounts.indexWhere((stored) => stored.id == account.id);
    if (index < 0) {
      _accounts.add(account);
    } else {
      _accounts[index] = account;
    }
  }

  int nextId() {
    var highestId = 0;

    for (final account in _accounts) {
      if (account.id > highestId) highestId = account.id;
    }

    return highestId + 1;
  }
}
