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

  setUpAll(() => registerFallbackValue(pair));

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
    when(() => buildGroup(any())).thenAnswer((_) async => result);
  }

  test('a built group is done', () async {
    buildAnswers(const FamilyGroupBuilt(7));

    expect(await cubit.build(pair), isTrue);
    expect(cubit.state.status, FamilyGroupSaveStatus.done);
  });

  test('a failed creation keeps the failure to show it', () async {
    buildAnswers(const FamilyGroupBuildFailed(NetworkFailure()));

    expect(await cubit.build(pair), isFalse);
    expect(cubit.state.status, FamilyGroupSaveStatus.failed);
    expect(cubit.state.isOffline, isTrue);
    expect(cubit.state.isCreationUnconfirmed, isFalse);
    expect(cubit.state.isStale, isFalse);
  });

  test('a creation timeout is flagged as unconfirmed', () async {
    buildAnswers(const FamilyGroupBuildFailed(ResponseTimeoutFailure()));

    await cubit.build(pair);

    expect(cubit.state.isCreationUnconfirmed, isTrue);
  });

  test('a member already in a group flags the list as stale', () async {
    buildAnswers(const FamilyGroupBuildFailed(ConflictFailure()));

    await cubit.build(pair);

    expect(cubit.state.isStale, isTrue);
  });

  test('a retry sends the same request again', () async {
    buildAnswers(const FamilyGroupBuildFailed(ServerFailure()));
    await cubit.build(pair);
    buildAnswers(const FamilyGroupBuilt(7));

    expect(await cubit.build(pair), isTrue);

    verify(() => buildGroup(pair)).called(2);
  });

  test('resetting clears a failure so the next pair starts clean', () async {
    buildAnswers(const FamilyGroupBuildFailed(ServerFailure()));
    await cubit.build(pair);

    cubit.reset();

    expect(cubit.state, const FamilyGroupBuilderState());
  });

  test('saving is visible while the build runs', () async {
    buildAnswers(const FamilyGroupBuilt(7));
    final states = <FamilyGroupBuilderState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.build(pair);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(states.map((state) => state.status), [
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
