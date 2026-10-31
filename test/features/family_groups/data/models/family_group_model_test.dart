import 'package:club_management_app/features/family_groups/data/models/family_group_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads id and name from the API response', () {
    final group = FamilyGroupModel.fromJson(const {
      'id': 7,
      'name': 'Familia Gómez',
      'createdAt': '2026-10-01T12:00:00Z',
    });

    expect(group.id, 7);
    expect(group.name, 'Familia Gómez');
    expect(group.hasName, isTrue);
  });

  test('a group without a name is valid', () {
    final group = FamilyGroupModel.fromJson(const {'id': 3, 'name': null});

    expect(group.name, isNull);
    expect(group.hasName, isFalse);
  });

  test('a blank name counts as no name', () {
    expect(const FamilyGroupModel(id: 1, name: '   ').hasName, isFalse);
  });

  test('always sends the name, because PATCH replaces the whole body', () {
    expect(FamilyGroupModel.bodyWithName(null), {'name': null});
    expect(FamilyGroupModel.bodyWithName('Familia Torres'), {
      'name': 'Familia Torres',
    });
  });

  group('the body that creates a group with its members', () {
    test('sends the name and the ids of every member', () {
      expect(
        FamilyGroupModel.bodyForCreation('Familia Torres', const [4, 5]),
        {
          'name': 'Familia Torres',
          'memberIds': [4, 5],
        },
      );
    });

    test('sends a null name when the group has none', () {
      expect(FamilyGroupModel.bodyForCreation(null, const [4, 5]), {
        'name': null,
        'memberIds': [4, 5],
      });
    });

    test('sends an empty list when there are no members yet', () {
      expect(FamilyGroupModel.bodyForCreation('Familia Torres', const []), {
        'name': 'Familia Torres',
        'memberIds': <int>[],
      });
    });
  });
}
