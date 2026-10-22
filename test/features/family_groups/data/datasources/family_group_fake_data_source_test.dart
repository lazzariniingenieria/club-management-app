import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/family_groups/data/datasources/family_group_fake_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FamilyGroupFakeDataSource source;

  setUp(() => source = FamilyGroupFakeDataSource(latency: Duration.zero));

  test('serves the seeded groups that match the fake roster', () async {
    final groups = await source.fetchGroups();

    expect(groups.map((group) => group.id), containsAll([1, 2]));
  });

  test('creates groups with the next id and keeps their name', () async {
    final created = await source.createGroup(name: 'Familia Torres');
    final fetched = await source.fetchGroup(created.id);

    expect(created.id, 3);
    expect(fetched.name, 'Familia Torres');
  });

  test('renames and clears a name', () async {
    await source.renameGroup(1, null);

    expect((await source.fetchGroup(1)).name, isNull);
  });

  test('an unknown group is a 404', () {
    expect(() => source.fetchGroup(99), throwsA(isA<NotFoundException>()));
  });
}
