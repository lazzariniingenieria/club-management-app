import '../../../../core/errors/exceptions.dart';
import '../../../members/data/datasources/member_remote_data_source.dart';
import '../models/family_group_model.dart';
import 'family_group_remote_data_source.dart';

class FamilyGroupFakeDataSource implements FamilyGroupRemoteDataSource {
  FamilyGroupFakeDataSource({
    required MemberRemoteDataSource members,
    this.latency = const Duration(milliseconds: 600),
  })  : _members = members,
        _names = {...seededGroups};

  final MemberRemoteDataSource _members;
  final Duration latency;
  final Map<int, String?> _names;

  static const Map<int, String?> seededGroups = {
    1: 'Familia Álvarez',
    2: null,
  };

  @override
  Future<FamilyGroupModel> fetchGroup(int familyGroupId) async {
    await Future<void>.delayed(latency);
    if (!_names.containsKey(familyGroupId)) {
      throw NotFoundException('Unknown family group $familyGroupId');
    }

    return FamilyGroupModel(id: familyGroupId, name: _names[familyGroupId]);
  }

  @override
  Future<List<FamilyGroupModel>> fetchGroups() async {
    await Future<void>.delayed(latency);

    return [
      for (final entry in _names.entries)
        FamilyGroupModel(id: entry.key, name: entry.value),
    ];
  }

  @override
  Future<FamilyGroupModel> createGroup({
    String? name,
    List<int> memberIds = const [],
  }) async {
    await Future<void>.delayed(latency);
    await _rejectUnavailable(memberIds);
    final id = _nextId();
    _names[id] = name;
    for (final memberId in memberIds) {
      await _members.assignFamilyGroup(memberId, id);
    }

    return FamilyGroupModel(id: id, name: name);
  }

  @override
  Future<void> renameGroup(int familyGroupId, String? name) async {
    await fetchGroup(familyGroupId);

    _names[familyGroupId] = name;
  }

  @override
  Future<void> deleteGroup(int familyGroupId) async {
    await fetchGroup(familyGroupId);

    final roster = await _members.fetchMembers();
    for (final member in roster) {
      if (member.familyGroupId == familyGroupId) {
        await _members.removeFromFamilyGroup(member.id);
      }
    }
    _names.remove(familyGroupId);
  }

  Future<void> _rejectUnavailable(List<int> memberIds) async {
    final roster = await _members.fetchMembers();
    final byId = {for (final member in roster) member.id: member};
    for (final memberId in memberIds) {
      if (!byId.containsKey(memberId)) {
        throw NotFoundException('Unknown member $memberId');
      }
    }
    if (memberIds.any((memberId) => byId[memberId]!.familyGroupId != null)) {
      throw ConflictException('A member already belongs to a family group');
    }
  }

  int _nextId() {
    var highestId = 0;

    for (final id in _names.keys) {
      if (id > highestId) highestId = id;
    }

    return highestId + 1;
  }
}
