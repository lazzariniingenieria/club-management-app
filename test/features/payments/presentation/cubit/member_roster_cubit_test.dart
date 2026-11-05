import 'dart:async';

import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/entities/member_collection_filter.dart';
import 'package:club_management_app/features/members/domain/usecases/load_members_use_case.dart';
import 'package:club_management_app/features/members/domain/usecases/watch_roster_changes_use_case.dart';
import 'package:club_management_app/features/payments/domain/usecases/watch_payment_changes_use_case.dart';
import 'package:club_management_app/features/payments/presentation/cubit/member_roster_cubit.dart';
import 'package:club_management_app/features/payments/presentation/cubit/member_roster_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/member_roster_data_source.dart';

class MockLoadMembersUseCase extends Mock implements LoadMembersUseCase {}

class MockWatchRosterChangesUseCase extends Mock
    implements WatchRosterChangesUseCase {}

class MockWatchPaymentChangesUseCase extends Mock
    implements WatchPaymentChangesUseCase {}

void main() {
  late MockLoadMembersUseCase useCase;
  late StreamController<void> rosterChanges;
  late StreamController<void> paymentChanges;
  late MemberRosterCubit cubit;

  final overdueMember = buildMember(
    id: 1,
    firstName: 'Juan',
    lastName: 'Zárate',
    daysOverdue: 42,
  );
  final upToDateMember = buildMember(
    id: 2,
    firstName: 'Ana',
    lastName: 'Álvarez',
  );
  final inactiveMember = buildMember(
    id: 3,
    firstName: 'Luis',
    lastName: 'Gómez',
    status: MemberStatus.inactive,
  );

  List<Member> roster() => [overdueMember, upToDateMember, inactiveMember];

  void stub(Either<Failure, List<Member>> result) {
    when(() => useCase()).thenAnswer((_) async => result);
  }

  MemberRosterReady readyState() => cubit.state as MemberRosterReady;

  setUp(() {
    useCase = MockLoadMembersUseCase();
    rosterChanges = StreamController<void>.broadcast();
    final watchRosterChanges = MockWatchRosterChangesUseCase();
    when(() => watchRosterChanges()).thenAnswer((_) => rosterChanges.stream);
    paymentChanges = StreamController<void>.broadcast();
    final watchPaymentChanges = MockWatchPaymentChangesUseCase();
    when(() => watchPaymentChanges()).thenAnswer((_) => paymentChanges.stream);
    cubit = MemberRosterCubit(
      loadMembers: useCase,
      watchRosterChanges: watchRosterChanges,
      watchPaymentChanges: watchPaymentChanges,
    );
  });

  tearDown(() async {
    await cubit.close();
    await rosterChanges.close();
    await paymentChanges.close();
  });

  test('starts loading so the list never opens on an empty roster', () {
    expect(cubit.state, const MemberRosterLoading());
  });

  test('sorts the roster by last name ignoring accents', () async {
    stub(Right(roster()));

    await cubit.load();

    expect(
      readyState().members.map((member) => member.lastName),
      ['Álvarez', 'Gómez', 'Zárate'],
    );
  });

  test('turns a failure into its Spanish message', () async {
    stub(const Left(NetworkFailure('Unreachable')));

    await cubit.load();

    expect(
        cubit.state, const MemberRosterFailure(AppStrings.loginNetworkError));
  });

  group('counters', () {
    setUp(() async {
      stub(Right(roster()));
      await cubit.load();
    });

    test('all counts only the members still in the club', () {
      expect(readyState().countFor(MemberCollectionFilter.all), 2);
    });

    test('inactive counts the members who were let go', () {
      expect(readyState().countFor(MemberCollectionFilter.inactive), 1);
    });

    test('overdue counts only the members behind on the fee', () {
      expect(readyState().countFor(MemberCollectionFilter.overdue), 1);
    });
  });

  group('search', () {
    setUp(() async {
      stub(Right(roster()));
      await cubit.load();
    });

    test('narrows the visible members without touching the counters', () {
      cubit.search('alvarez');

      expect(
        readyState().visibleMembers(MemberCollectionFilter.all).single.id,
        upToDateMember.id,
      );
      expect(readyState().countFor(MemberCollectionFilter.all), 2);
    });

    test('combines with the active filter', () {
      cubit.search('Zárate');

      expect(
        readyState().visibleMembers(MemberCollectionFilter.overdue),
        hasLength(1),
      );
      expect(
        readyState().visibleMembers(MemberCollectionFilter.all),
        hasLength(1),
      );
    });

    test('clearing brings the whole roster back', () {
      cubit.search('Zárate');
      cubit.clearSearch();

      expect(readyState().hasSearchQuery, isFalse);
      expect(readyState().visibleMembers(MemberCollectionFilter.all),
          hasLength(2));
    });

    test('survives a reload so a pull to refresh keeps the query', () async {
      cubit.search('Gómez');

      await cubit.load();

      expect(readyState().searchQuery, 'Gómez');
    });
  });

  group('a failed reload', () {
    setUp(() async {
      stub(Right(roster()));
      await cubit.load();
      cubit.search('Zárate');
      stub(const Left(NetworkFailure('Unreachable')));
      await cubit.load();
    });

    test('carries the roster it already had', () {
      final failure = cubit.state as MemberRosterFailure;

      expect(failure.message, AppStrings.loginNetworkError);
      expect(failure.previous?.members, hasLength(3));
    });

    test('does not drop the search the admin typed', () {
      final failure = cubit.state as MemberRosterFailure;

      expect(failure.previous?.searchQuery, 'Zárate');
    });

    test('a later retry comes back with that search intact', () async {
      stub(Right(roster()));

      await cubit.load();

      expect(readyState().searchQuery, 'Zárate');
    });

    test('keeps the search usable while the error is on screen', () {
      cubit.search('Álvarez');

      final failure = cubit.state as MemberRosterFailure;

      expect(failure.previous?.searchQuery, 'Álvarez');
    });

    test('reports a second failure instead of swallowing it', () async {
      final states = <MemberRosterState>[];
      cubit.stream.listen(states.add);
      stub(const Left(NetworkFailure('Unreachable')));

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states.whereType<MemberRosterFailure>(), hasLength(1));
    });

    test('never shows the skeleton again once there is data', () async {
      final states = <MemberRosterState>[];
      cubit.stream.listen(states.add);
      stub(const Left(NetworkFailure('Unreachable')));

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states.whereType<MemberRosterLoading>(), isEmpty);
    });
  });

  test('a first load that fails has no roster to fall back on', () async {
    stub(const Left(NetworkFailure('Unreachable')));

    await cubit.load();

    expect((cubit.state as MemberRosterFailure).previous, isNull);
  });

  test('keeps a search the admin typed while the reload was in flight',
      () async {
    stub(Right(roster()));
    await cubit.load();

    final reload = cubit.load();
    cubit.search('Álvarez');
    await reload;

    expect(readyState().searchQuery, 'Álvarez');
  });

  test('ignores a second load while one is already in flight', () async {
    stub(Right(roster()));

    await Future.wait([cubit.load(), cubit.load()]);

    verify(() => useCase()).called(1);
  });
  test('a reload keeps the rows on screen instead of the skeleton', () async {
    stub(Right(roster()));
    await cubit.load();

    final states = <MemberRosterState>[];
    cubit.stream.listen(states.add);
    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(states.whereType<MemberRosterLoading>(), isEmpty);
  });

  group('a change to the roster made elsewhere', () {
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('reloads the list on its own, keeping the search', () async {
      stub(Right(roster()));
      await cubit.load();
      cubit.search('ana');

      rosterChanges.add(null);
      await settle();

      verify(() => useCase()).called(2);
      expect(readyState().searchQuery, 'ana');
    });

    test('arriving during a load is not lost: one more load follows', () async {
      final firstLoad = Completer<Either<Failure, List<Member>>>();
      when(() => useCase()).thenAnswer((_) => firstLoad.future);

      final loading = cubit.load();
      rosterChanges.add(null);
      await settle();
      stub(Right(roster()));
      firstLoad.complete(Right(roster()));
      await loading;

      verify(() => useCase()).called(2);
    });

    test('is no longer heard once the list is closed', () async {
      await cubit.close();

      expect(rosterChanges.hasListener, isFalse);
    });
  });

  group('a payment recorded or voided elsewhere', () {
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('reloads the list, so the mora shown is the new one', () async {
      stub(Right(roster()));
      await cubit.load();

      paymentChanges.add(null);
      await settle();

      verify(() => useCase()).called(2);
    });

    test('is no longer heard once the list is closed', () async {
      await cubit.close();

      expect(paymentChanges.hasListener, isFalse);
    });
  });
}
