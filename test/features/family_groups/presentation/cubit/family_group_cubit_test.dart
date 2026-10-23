import 'dart:async';

import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group_detail.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/leave_family_group_use_case.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/load_family_group_detail_use_case.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/rename_family_group_use_case.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/watch_family_group_changes_use_case.dart';
import 'package:club_management_app/features/family_groups/presentation/cubit/family_group_cubit.dart';
import 'package:club_management_app/features/family_groups/presentation/cubit/family_group_state.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/usecases/watch_roster_changes_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLoadDetail extends Mock implements LoadFamilyGroupDetailUseCase {}

class MockRename extends Mock implements RenameFamilyGroupUseCase {}

class MockLeave extends Mock implements LeaveFamilyGroupUseCase {}

class MockWatchRoster extends Mock implements WatchRosterChangesUseCase {}

class MockWatchGroups extends Mock implements WatchFamilyGroupChangesUseCase {}

const gomez = FamilyGroup(id: 7, name: 'Familia Gómez');

const tomas = Member(
  id: 2,
  firstName: 'Tomás',
  lastName: 'Gómez',
  dni: '30111222',
  status: MemberStatus.active,
  daysOverdue: 0,
  familyGroupId: 7,
);

const laura = Member(
  id: 3,
  firstName: 'Laura',
  lastName: 'Gómez',
  dni: '30111333',
  status: MemberStatus.active,
  daysOverdue: 0,
  familyGroupId: 7,
);

FamilyGroupDetail detailWith(List<Member> members) =>
    FamilyGroupDetail(group: gomez, members: members);

void main() {
  late MockLoadDetail loadDetail;
  late MockLeave leave;
  late StreamController<void> rosterChanges;
  late StreamController<void> groupChanges;
  late FamilyGroupCubit cubit;

  void detailAnswers(List<Either<Failure, FamilyGroupDetail>> results) {
    final queue = [...results];
    when(() => loadDetail(7)).thenAnswer((_) async => queue.removeAt(0));
  }

  setUp(() {
    loadDetail = MockLoadDetail();
    leave = MockLeave();
    rosterChanges = StreamController<void>.broadcast();
    groupChanges = StreamController<void>.broadcast();
    final watchRoster = MockWatchRoster();
    final watchGroups = MockWatchGroups();
    when(() => watchRoster()).thenAnswer((_) => rosterChanges.stream);
    when(() => watchGroups()).thenAnswer((_) => groupChanges.stream);
    cubit = FamilyGroupCubit(
      loadDetail: loadDetail,
      rename: MockRename(),
      leave: leave,
      watchRosterChanges: watchRoster,
      watchGroupChanges: watchGroups,
    );
  });

  tearDown(() async {
    await cubit.close();
    await rosterChanges.close();
    await groupChanges.close();
  });

  Future<void> loadWithBoth() async {
    detailAnswers([Right(detailWith(const [tomas, laura]))]);
    await cubit.load(7);
  }

  group('remove', () {
    test('a confirmed removal reports no failure', () async {
      await loadWithBoth();
      when(() => leave(2)).thenAnswer((_) async => const Right(null));

      expect(await cubit.remove(tomas), isNull);
    });

    test('a timeout already applied on the server counts as done', () async {
      await loadWithBoth();
      when(() => leave(2))
          .thenAnswer((_) async => const Left(ResponseTimeoutFailure()));
      detailAnswers([Right(detailWith(const [laura]))]);

      expect(await cubit.remove(tomas), isNull);
      expect(cubit.state, FamilyGroupReady(detailWith(const [laura])));
    });

    test('a timeout that did not apply keeps the failure', () async {
      await loadWithBoth();
      when(() => leave(2))
          .thenAnswer((_) async => const Left(ResponseTimeoutFailure()));
      detailAnswers([Right(detailWith(const [tomas, laura]))]);

      expect(await cubit.remove(tomas), const ResponseTimeoutFailure());
    });

    test('a server error is reported without reloading', () async {
      await loadWithBoth();
      when(() => leave(2))
          .thenAnswer((_) async => const Left(ServerFailure()));

      expect(await cubit.remove(tomas), const ServerFailure());
      verify(() => loadDetail(7)).called(1);
    });
  });

  test('a change during a load triggers a single extra reload', () async {
    final pending = Completer<Either<Failure, FamilyGroupDetail>>();
    var calls = 0;
    when(() => loadDetail(7)).thenAnswer((_) {
      calls++;

      return calls == 1
          ? pending.future
          : Future.value(Right(detailWith(const [laura])));
    });

    final loading = cubit.load(7);
    rosterChanges.add(null);
    groupChanges.add(null);
    await Future<void>.delayed(Duration.zero);
    pending.complete(Right(detailWith(const [tomas, laura])));
    await loading;

    expect(calls, 2);
    expect(cubit.state, FamilyGroupReady(detailWith(const [laura])));
  });

  test('a change after loading reloads the group', () async {
    await loadWithBoth();
    detailAnswers([Right(detailWith(const [laura]))]);

    groupChanges.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, FamilyGroupReady(detailWith(const [laura])));
  });

  test('closing stops listening to changes', () async {
    await cubit.close();

    expect(rosterChanges.hasListener, isFalse);
    expect(groupChanges.hasListener, isFalse);
  });
}
