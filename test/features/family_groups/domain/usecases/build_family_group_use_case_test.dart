import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group_build.dart';
import 'package:club_management_app/features/family_groups/domain/repositories/family_group_repository.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/build_family_group_use_case.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/repositories/member_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockFamilyGroupRepository extends Mock implements FamilyGroupRepository {}

class MockMemberRepository extends Mock implements MemberRepository {}

void main() {
  late MockFamilyGroupRepository groups;
  late MockMemberRepository members;
  late BuildFamilyGroupUseCase buildGroup;

  const request = FamilyGroupBuildRequest(
    memberIds: [1, 2],
    name: '  Familia Gómez ',
  );

  Member memberIn(int id, int? familyGroupId) => Member(
        id: id,
        firstName: 'Socio',
        lastName: '$id',
        dni: '3000000$id',
        status: MemberStatus.active,
        daysOverdue: 0,
        familyGroupId: familyGroupId,
      );

  void stubCreation(Either<Failure, FamilyGroup> result) {
    when(
      () => groups.createGroup(
        name: any(named: 'name'),
        memberIds: any(named: 'memberIds'),
      ),
    ).thenAnswer((_) async => result);
  }

  void stubMemberGroups(Map<int, int?> groupOf) {
    for (final MapEntry(:key, :value) in groupOf.entries) {
      when(() => members.loadMember(key))
          .thenAnswer((_) async => Right(memberIn(key, value)));
    }
  }

  setUp(() {
    groups = MockFamilyGroupRepository();
    members = MockMemberRepository();
    buildGroup = BuildFamilyGroupUseCase(groups: groups, members: members);
    stubCreation(const Right(FamilyGroup(id: 7)));
  });

  test('creates the group with its members in a single request', () async {
    final result = await buildGroup(request);

    expect(result, const FamilyGroupBuilt(7));
    verify(
      () => groups.createGroup(name: 'Familia Gómez', memberIds: [1, 2]),
    ).called(1);
    verifyNever(() => members.assignFamilyGroup(any(), any()));
  });

  test('tells the roster that the groups changed', () async {
    await buildGroup(request);

    verify(() => members.notifyRosterChanged()).called(1);
  });

  test('an empty name creates a group without name', () async {
    await buildGroup(const FamilyGroupBuildRequest(memberIds: [1], name: ' '));

    verify(() => groups.createGroup(name: null, memberIds: [1])).called(1);
  });

  group('a creation that failed for sure', () {
    test('is reported as it is and nothing is reread', () async {
      stubCreation(const Left(NetworkFailure()));

      final result = await buildGroup(request) as FamilyGroupBuildFailed;

      expect(result.failure, const NetworkFailure());
      expect(result.isCreationUnconfirmed, isFalse);
      expect(result.isStale, isFalse);
      verifyNever(() => members.loadMember(any()));
      verifyNever(() => members.notifyRosterChanged());
    });
  });

  group('a creation nobody answered', () {
    setUp(() => stubCreation(const Left(ResponseTimeoutFailure())));

    test('is built when both members now share a group', () async {
      stubMemberGroups({1: 7, 2: 7});

      final result = await buildGroup(request);

      expect(result, const FamilyGroupBuilt(7));
      verify(() => members.notifyRosterChanged()).called(1);
    });

    test('is unconfirmed while the members still have no group', () async {
      stubMemberGroups({1: null, 2: null});

      final result = await buildGroup(request) as FamilyGroupBuildFailed;

      expect(result.isCreationUnconfirmed, isTrue);
    });

    test('is unconfirmed when the members cannot be read', () async {
      when(() => members.loadMember(any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await buildGroup(request) as FamilyGroupBuildFailed;

      expect(result.isCreationUnconfirmed, isTrue);
    });
  });

  group('a creation that found a member already in a group', () {
    setUp(() => stubCreation(const Left(ConflictFailure())));

    test('means the list was stale when they are in different groups',
        () async {
      stubMemberGroups({1: null, 2: 3});

      final result = await buildGroup(request) as FamilyGroupBuildFailed;

      expect(result.isStale, isTrue);
      verify(() => members.notifyRosterChanged()).called(1);
    });

    test('is built when the earlier request already put both together',
        () async {
      stubMemberGroups({1: 7, 2: 7});

      final result = await buildGroup(request);

      expect(result, const FamilyGroupBuilt(7));
    });
  });
}
