import '../../../../core/errors/exceptions.dart';
import '../models/family_group_model.dart';
import 'family_group_remote_data_source.dart';

class FamilyGroupFakeDataSource implements FamilyGroupRemoteDataSource {
  FamilyGroupFakeDataSource({this.latency = const Duration(milliseconds: 600)})
      : _names = {...seededGroups};

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
  Future<FamilyGroupModel> createGroup({String? name}) async {
    await Future<void>.delayed(latency);
    final id = _nextId();
    _names[id] = name;

    return FamilyGroupModel(id: id, name: name);
  }

  @override
  Future<void> renameGroup(int familyGroupId, String? name) async {
    await fetchGroup(familyGroupId);

    _names[familyGroupId] = name;
  }

  int _nextId() {
    var highestId = 0;

    for (final id in _names.keys) {
      if (id > highestId) highestId = id;
    }

    return highestId + 1;
  }
}
