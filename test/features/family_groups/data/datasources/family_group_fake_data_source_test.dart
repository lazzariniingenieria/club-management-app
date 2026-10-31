import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/family_groups/data/datasources/family_group_fake_data_source.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemberFakeDataSource members;
  late FamilyGroupFakeDataSource source;

  Future<List<int>> idsWithoutGroup() async => [
        for (final member in await members.fetchMembers())
          if (member.familyGroupId == null) member.id,
      ];

  Future<List<int>> idsIn(int familyGroupId) async => [
        for (final member in await members.fetchMembers())
          if (member.familyGroupId == familyGroupId) member.id,
      ];

  setUp(() {
    members = MemberFakeDataSource(latency: Duration.zero);
    source = FamilyGroupFakeDataSource(members: members, latency: Duration.zero);
  });

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

  group('creating a group with its members', () {
    test('puts every member in it', () async {
      final free = (await idsWithoutGroup()).take(2).toList();

      final created = await source.createGroup(memberIds: free);

      expect(await idsIn(created.id), free);
    });

    test('is a 409 when a member already has a group, and creates nothing',
        () async {
      final free = (await idsWithoutGroup()).first;
      final grouped = (await idsIn(1)).first;

      await expectLater(
        source.createGroup(memberIds: [free, grouped]),
        throwsA(isA<ConflictException>()),
      );

      expect(await source.fetchGroups(), hasLength(2));
      expect(await idsWithoutGroup(), contains(free));
    });

    test('is a 404 when a member is not in the club', () {
      expect(
        source.createGroup(memberIds: const [9999]),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('deleting a group', () {
    test('leaves its members without group and removes the group', () async {
      final inGroup = await idsIn(1);
      expect(inGroup, isNotEmpty);

      await source.deleteGroup(1);

      expect(await idsIn(1), isEmpty);
      expect(await idsWithoutGroup(), containsAll(inGroup));
      expect(() => source.fetchGroup(1), throwsA(isA<NotFoundException>()));
    });

    test('is a 404 for an unknown group', () {
      expect(() => source.deleteGroup(99), throwsA(isA<NotFoundException>()));
    });
  });
}
