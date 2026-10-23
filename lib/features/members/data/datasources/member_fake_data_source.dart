import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/member_draft.dart';
import '../models/member_model.dart';
import 'member_remote_data_source.dart';

class MemberFakeDataSource implements MemberRemoteDataSource {
  MemberFakeDataSource({this.latency = const Duration(milliseconds: 600)})
      : _roster = [...roster];

  final Duration latency;
  final List<MemberModel> _roster;

  static const int activeMembers = 34;
  static const int inactiveMembers = 6;
  static const int overdueMembers = 5;
  static const int totalMembers = activeMembers + inactiveMembers;

  static final List<MemberModel> roster = _buildRoster();

  @override
  Future<List<MemberModel>> fetchMembers() async {
    await Future<void>.delayed(latency);

    return [..._roster];
  }

  @override
  Future<MemberModel> fetchMember(int memberId) async {
    await Future<void>.delayed(latency);

    for (final member in _roster) {
      if (member.id == memberId) return member;
    }
    throw NotFoundException('Unknown member $memberId');
  }

  @override
  Future<void> createMember(MemberDraft draft) async {
    await Future<void>.delayed(latency);
    _rejectDuplicatedDni(draft.dni);

    _roster.add(
      MemberModel(
        id: _nextId(),
        firstName: draft.firstName,
        lastName: draft.lastName,
        dni: draft.dni,
        status: MemberStatus.active,
        daysOverdue: 0,
        phone: _orNull(draft.phone),
        email: _orNull(draft.email),
        joinedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateMember(int memberId, MemberDraft draft) async {
    await Future<void>.delayed(latency);
    _rejectDuplicatedDni(draft.dni, keeping: memberId);

    _replace(
      memberId,
      (current) => MemberModel(
        id: current.id,
        firstName: draft.firstName,
        lastName: draft.lastName,
        dni: draft.dni,
        status: current.status,
        daysOverdue: current.daysOverdue,
        phone: _orNull(draft.phone),
        email: _orNull(draft.email),
        familyGroupId: current.familyGroupId,
        joinedAt: current.joinedAt,
      ),
    );
  }

  @override
  Future<void> setMemberActive(int memberId, {required bool isActive}) async {
    await Future<void>.delayed(latency);

    _replace(
      memberId,
      (current) => _withStanding(
        current,
        status: isActive ? MemberStatus.active : MemberStatus.inactive,
        daysOverdue: isActive ? current.daysOverdue : 0,
      ),
    );
  }

  @override
  Future<void> assignFamilyGroup(int memberId, int familyGroupId) async {
    await Future<void>.delayed(latency);

    _replace(memberId, (current) => _inGroup(current, familyGroupId));
  }

  @override
  Future<void> removeFromFamilyGroup(int memberId) async {
    await Future<void>.delayed(latency);

    _replace(memberId, (current) => _inGroup(current, null));
  }

  static MemberModel _inGroup(MemberModel current, int? familyGroupId) {
    return MemberModel(
      id: current.id,
      firstName: current.firstName,
      lastName: current.lastName,
      dni: current.dni,
      status: current.status,
      daysOverdue: current.daysOverdue,
      phone: current.phone,
      email: current.email,
      familyGroupId: familyGroupId,
      joinedAt: current.joinedAt,
    );
  }

  void setDaysOverdue(int memberId, int daysOverdue) {
    _replace(
      memberId,
      (current) => _withStanding(
        current,
        status: current.status,
        daysOverdue: current.isActive ? daysOverdue : 0,
      ),
    );
  }

  void _replace(int memberId, MemberModel Function(MemberModel) change) {
    final index = _indexOf(memberId);

    _roster[index] = change(_roster[index]);
  }

  static MemberModel _withStanding(
    MemberModel current, {
    required MemberStatus status,
    required int daysOverdue,
  }) {
    return MemberModel(
      id: current.id,
      firstName: current.firstName,
      lastName: current.lastName,
      dni: current.dni,
      status: status,
      daysOverdue: daysOverdue,
      phone: current.phone,
      email: current.email,
      familyGroupId: current.familyGroupId,
      joinedAt: current.joinedAt,
    );
  }

  int _indexOf(int memberId) {
    final index = _roster.indexWhere((member) => member.id == memberId);
    if (index < 0) throw ServerException('Unknown member $memberId');

    return index;
  }

  void _rejectDuplicatedDni(String dni, {int? keeping}) {
    for (final member in _roster) {
      if (member.dni == dni && member.id != keeping) {
        throw ConflictException('Duplicated dni');
      }
    }
  }

  int _nextId() {
    var highestId = 0;

    for (final member in _roster) {
      if (member.id > highestId) highestId = member.id;
    }

    return highestId + 1;
  }

  static String? _orNull(String value) => value.isEmpty ? null : value;

  static List<MemberModel> _buildRoster() {
    return [
      for (var index = 0; index < totalMembers; index++) _memberAt(index),
    ];
  }

  static MemberModel _memberAt(int index) {
    final isActive = index < activeMembers;

    return MemberModel(
      id: index + 1,
      firstName: _firstNames[index % _firstNames.length],
      lastName: _lastNames[(index ~/ _firstNames.length) % _lastNames.length],
      dni: '${20000000 + index * 13577}',
      status: isActive ? MemberStatus.active : MemberStatus.inactive,
      daysOverdue: isActive ? _daysOverdueAt(index) : 0,
      familyGroupId: _familyGroupAt(index),
      joinedAt: DateTime(2024, 1 + index % 12, 1 + index % 27),
    );
  }

  static int? _familyGroupAt(int index) {
    for (final entry in _familyGroups.entries) {
      if (entry.value.contains(index)) return entry.key;
    }

    return null;
  }

  static const Map<int, Set<int>> _familyGroups = {
    1: {0, 1, 2},
    2: {24, 25},
  };

  static int _daysOverdueAt(int index) {
    final isOverdue =
        index % _overdueEvery == 0 && index < overdueMembers * _overdueEvery;

    return isOverdue ? 12 + (index % 7) * 15 : 0;
  }

  static const int _overdueEvery = 6;

  static const List<String> _firstNames = [
    'Juan',
    'María',
    'Carlos',
    'Lucía',
    'Martín',
    'Sofía',
    'Diego',
    'Valentina',
    'Jorge',
    'Camila',
    'Pablo',
    'Agustina',
    'Nicolás',
    'Florencia',
    'Matías',
    'Julieta',
    'Federico',
    'Micaela',
    'Santiago',
    'Rocío',
    'Gonzalo',
    'Paula',
    'Emiliano',
    'Ana',
  ];

  static const List<String> _lastNames = [
    'Álvarez',
    'Gómez',
    'Fernández',
    'Rodríguez',
    'López',
    'Martínez',
    'Pérez',
    'Sánchez',
    'Romero',
    'Torres',
    'Benítez',
    'Acosta',
    'Medina',
    'Suárez',
    'Herrera',
    'Castro',
    'Ortiz',
    'Silva',
    'Molina',
    'Navarro',
    'Vega',
  ];
}
