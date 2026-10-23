import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group_build.dart';
import 'package:club_management_app/features/family_groups/domain/repositories/family_group_repository.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/build_family_group_use_case.dart';
import 'package:club_management_app/features/members/domain/entities/family_group_assignment.dart';
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

  void assignmentAnswers(FamilyGroupAssignment assignment) {
    when(() => members.assignFamilyGroupToAll(any(), any()))
        .thenAnswer((_) async => assignment);
  }

  setUp(() {
    groups = MockFamilyGroupRepository();
    members = MockMemberRepository();
    buildGroup = BuildFamilyGroupUseCase(groups: groups, members: members);
    when(() => groups.createGroup(name: any(named: 'name')))
        .thenAnswer((_) async => const Right(FamilyGroup(id: 7)));
    assignmentAnswers(const FamilyGroupAssignment(assignedMemberIds: {1, 2}));
  });

  test('creates the group with the trimmed name and assigns both', () async {
    final result = await buildGroup(request);

    expect(result, const FamilyGroupBuilt(7));
    verify(() => groups.createGroup(name: 'Familia Gómez')).called(1);
    verify(() => members.assignFamilyGroupToAll([1, 2], 7)).called(1);
  });

  test('an empty name creates a group without name', () async {
    await buildGroup(const FamilyGroupBuildRequest(memberIds: [1], name: ' '));

    verify(() => groups.createGroup(name: null)).called(1);
  });

  test('a failed creation assigns nobody and is not partial', () async {
    when(() => groups.createGroup(name: any(named: 'name')))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await buildGroup(request);

    expect(result, isA<FamilyGroupBuildFailed>());
    expect((result as FamilyGroupBuildFailed).isPartial, isFalse);
    verifyNever(() => members.assignFamilyGroupToAll(any(), any()));
  });

  test('remembers what was done when an assignment fails', () async {
    assignmentAnswers(
      const FamilyGroupAssignment(
        assignedMemberIds: {1},
        failure: ServerFailure(),
      ),
    );

    final result = await buildGroup(request) as FamilyGroupBuildFailed;

    expect(result.isPartial, isTrue);
    expect(result.progress.familyGroupId, 7);
    expect(result.progress.assignedMemberIds, {1});
  });

  test('a retry finishes only what is missing, on the same group', () async {
    const progress = FamilyGroupBuildProgress(
      familyGroupId: 7,
      assignedMemberIds: {1},
    );

    final result = await buildGroup(request, progress: progress);

    expect(result, const FamilyGroupBuilt(7));
    verifyNever(() => groups.createGroup(name: any(named: 'name')));
    verify(() => members.assignFamilyGroupToAll([2], 7)).called(1);
  });
}
