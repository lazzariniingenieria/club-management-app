import 'dart:async';

import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/admin/presentation/cubit/admin_family_groups_cubit.dart';
import 'package:club_management_app/features/admin/presentation/cubit/admin_family_groups_state.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group.dart';
import 'package:club_management_app/features/family_groups/domain/entities/family_group_candidates.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/load_family_group_candidates_use_case.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/watch_family_group_changes_use_case.dart';
import 'package:club_management_app/features/members/domain/usecases/watch_roster_changes_use_case.dart';
import 'package:club_management_app/features/payments/domain/usecases/watch_payment_changes_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/member_roster_data_source.dart';

class MockLoadCandidates extends Mock
    implements LoadFamilyGroupCandidatesUseCase {}

class MockWatchRoster extends Mock implements WatchRosterChangesUseCase {}

class MockWatchGroups extends Mock implements WatchFamilyGroupChangesUseCase {}

class MockWatchPayments extends Mock implements WatchPaymentChangesUseCase {}

void main() {
  late MockLoadCandidates loadCandidates;
  late StreamController<void> paymentChanges;
  late AdminFamilyGroupsCubit cubit;

  final candidates = FamilyGroupCandidates(
    roster: [
      buildMember(id: 1, lastName: 'Gómez', familyGroupId: 7),
      buildMember(id: 2, lastName: 'Acosta', familyGroupId: 8),
    ],
    groups: const [
      FamilyGroup(id: 7, name: 'Familia Gómez'),
      FamilyGroup(id: 8, name: 'Familia Acosta'),
    ],
  );

  void stub(Either<Failure, FamilyGroupCandidates> result) {
    when(() => loadCandidates()).thenAnswer((_) async => result);
  }

  setUp(() {
    loadCandidates = MockLoadCandidates();
    paymentChanges = StreamController<void>.broadcast();
    final watchRoster = MockWatchRoster();
    final watchGroups = MockWatchGroups();
    final watchPayments = MockWatchPayments();
    when(() => watchRoster()).thenAnswer((_) => const Stream.empty());
    when(() => watchGroups()).thenAnswer((_) => const Stream.empty());
    when(() => watchPayments()).thenAnswer((_) => paymentChanges.stream);
    cubit = AdminFamilyGroupsCubit(
      loadGroups: loadCandidates,
      watchRosterChanges: watchRoster,
      watchGroupChanges: watchGroups,
      watchPaymentChanges: watchPayments,
    );
  });

  tearDown(() async {
    await cubit.close();
    await paymentChanges.close();
  });

  test('lists the groups ordered by their first member', () async {
    stub(Right(candidates));

    await cubit.load();

    final ready = cubit.state as AdminFamilyGroupsReady;
    expect(ready.groups.map((group) => group.group.id), [8, 7]);
  });

  test('reloads when a payment changes, so the mora badge stays true',
      () async {
    stub(Right(candidates));
    await cubit.load();

    paymentChanges.add(null);
    await pumpEventQueue();

    verify(() => loadCandidates()).called(2);
  });

  test('a failed refresh keeps the list it had', () async {
    stub(Right(candidates));
    await cubit.load();
    stub(const Left(NetworkFailure()));

    await cubit.load();

    final failure = cubit.state as AdminFamilyGroupsFailure;
    expect(failure.previous?.groups, hasLength(2));
  });

  test('the search survives a reload', () async {
    stub(Right(candidates));
    await cubit.load();
    cubit.search('gomez');

    await cubit.load();

    final ready = cubit.state as AdminFamilyGroupsReady;
    expect(ready.searchQuery, 'gomez');
    expect(ready.visibleGroups.single.group.id, 7);
  });
}
