import '../../domain/entities/family_group.dart';

class FamilyGroupModel extends FamilyGroup {
  const FamilyGroupModel({required super.id, super.name});

  static const String _idKey = 'id';
  static const String _nameKey = 'name';

  factory FamilyGroupModel.fromJson(Map<String, dynamic> json) {
    return FamilyGroupModel(
      id: (json[_idKey] as num).toInt(),
      name: json[_nameKey] as String?,
    );
  }

  static Map<String, dynamic> bodyWithName(String? name) => {_nameKey: name};
}
