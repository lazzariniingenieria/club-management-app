import 'dart:async';

import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/load_family_group_use_case.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/watch_family_group_changes_use_case.dart';
import 'package:club_management_app/features/family_groups/presentation/cubit/family_group_name_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLoadGroup extends Mock implements LoadFamilyGroupUseCase {}

class MockWatchGroups extends Mock implements WatchFamilyGroupChangesUseCase {}

void main() {
  late MockLoadGroup loadGroup;
  late StreamController<void> changes;
  late FamilyGroupNameCubit cubit;

  setUp(() {
    loadGroup = MockLoadGroup();
    changes = StreamController<void>.broadcast();
    final watch = MockWatchGroups();
    when(() => watch()).thenAnswer((_) => changes.stream);
    cubit = FamilyGroupNameCubit(loadGroup: loadGroup, watchChanges: watch);
  });

  tearDown(() async {
    await cubit.close();
    await changes.close();
  });

  void groupAnswers(Either<Failure, FamilyGroup> result) {
    when(() => loadGroup(7)).thenAnswer((_) async => result);
  }

  test('loads the group name', () async {
    groupAnswers(const Right(FamilyGroup(id: 7, name: 'A')));

    await cubit.load(7);

    expect(
      cubit.state,
      const FamilyGroupNameState(
        isLoading: false,
        group: FamilyGroup(id: 7, name: 'A'),
      ),
    );
  });

  test('a failed read leaves the name empty instead of an error', () async {
    groupAnswers(const Left(NetworkFailure()));

    await cubit.load(7);

    expect(cubit.state, const FamilyGroupNameState(isLoading: false));
  });

  test('a renamed group reloads its name', () async {
    groupAnswers(const Right(FamilyGroup(id: 7, name: 'A')));
    await cubit.load(7);
    groupAnswers(const Right(FamilyGroup(id: 7, name: 'B')));

    changes.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.group, const FamilyGroup(id: 7, name: 'B'));
  });

  test('closing stops listening to changes', () async {
    await cubit.close();

    expect(changes.hasListener, isFalse);
  });
}
