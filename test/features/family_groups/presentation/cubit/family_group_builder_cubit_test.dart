import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group_build.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/build_family_group_use_case.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/join_family_group_use_case.dart';
import 'package:club_management_app/features/family_groups/presentation/cubit/family_group_builder_cubit.dart';
import 'package:club_management_app/features/family_groups/presentation/cubit/family_group_builder_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockBuildGroup extends Mock implements BuildFamilyGroupUseCase {}

class MockJoinGroup extends Mock implements JoinFamilyGroupUseCase {}

void main() {
  late MockBuildGroup buildGroup;
  late MockJoinGroup joinGroup;
  late FamilyGroupBuilderCubit cubit;

  const pair = FamilyGroupBuildRequest(memberIds: [4, 5], name: 'Familia');
  const otherPair = FamilyGroupBuildRequest(memberIds: [4, 6], name: '');
  const halfWay = FamilyGroupBuildProgress(
    familyGroupId: 7,
    assignedMemberIds: {4},
  );

  setUpAll(() {
    registerFallbackValue(pair);
    registerFallbackValue(const FamilyGroupBuildProgress());
  });

  setUp(() {
    buildGroup = MockBuildGroup();
    joinGroup = MockJoinGroup();
    cubit = FamilyGroupBuilderCubit(
      buildGroup: buildGroup,
      joinGroup: joinGroup,
    );
  });

  tearDown(() => cubit.close());

  void buildAnswers(FamilyGroupBuildResult result) {
    when(() => buildGroup(any(), progress: any(named: 'progress')))
        .thenAnswer((_) async => result);
  }

  test('a failed assignment keeps the progress for the retry', () async {
    buildAnswers(const FamilyGroupBuildFailed(ServerFailure(), halfWay));

    expect(await cubit.build(pair), isFalse);
    expect(cubit.state.status, FamilyGroupSaveStatus.failed);
    expect(cubit.state.progress, halfWay);
    expect(cubit.state.isPartial, isTrue);
  });

  test('the retry for the same pair resumes on the same group', () async {
    buildAnswers(const FamilyGroupBuildFailed(ServerFailure(), halfWay));
    await cubit.build(pair);
    buildAnswers(const FamilyGroupBuilt(7));

    cubit.prepareFor(pair.memberIds);
    expect(await cubit.build(pair), isTrue);

    verify(() => buildGroup(pair, progress: halfWay)).called(1);
  });

  test('another pair starts from scratch', () async {
    buildAnswers(const FamilyGroupBuildFailed(ServerFailure(), halfWay));
    await cubit.build(pair);
    buildAnswers(const FamilyGroupBuilt(8));

    cubit.prepareFor(otherPair.memberIds);
    expect(cubit.state.failure, isNull);
    await cubit.build(otherPair);

    verify(
      () => buildGroup(otherPair, progress: const FamilyGroupBuildProgress()),
    ).called(1);
  });

  test('a creation timeout is flagged as unconfirmed', () async {
    buildAnswers(
      const FamilyGroupBuildFailed(
        ResponseTimeoutFailure(),
        FamilyGroupBuildProgress(),
      ),
    );

    await cubit.build(pair);

    expect(cubit.state.isCreationUnconfirmed, isTrue);
  });

  test('saving is visible while the build runs', () async {
    buildAnswers(const FamilyGroupBuilt(7));
    final states = <FamilyGroupBuilderState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.build(pair);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(states.map((state) => state.status), [
      FamilyGroupSaveStatus.idle,
      FamilyGroupSaveStatus.saving,
      FamilyGroupSaveStatus.done,
    ]);
  });

  test('a failed join keeps the failure to show it', () async {
    when(() => joinGroup(4, 7))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    expect(await cubit.join(4, 7), isFalse);
    expect(cubit.state.failure, const NetworkFailure());
    expect(cubit.state.status, FamilyGroupSaveStatus.failed);
  });

  test('a successful join is done', () async {
    when(() => joinGroup(4, 7)).thenAnswer((_) async => const Right(null));

    expect(await cubit.join(4, 7), isTrue);
    expect(cubit.state.status, FamilyGroupSaveStatus.done);
  });
}
