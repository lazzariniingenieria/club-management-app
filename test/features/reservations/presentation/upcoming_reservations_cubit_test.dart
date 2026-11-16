import 'dart:async';

import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/club/domain/entities/club.dart';
import 'package:club_management_app/features/club/domain/usecases/load_club_use_case.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/usecases/watch_roster_changes_use_case.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:club_management_app/features/reservations/domain/entities/upcoming_reservations.dart';
import 'package:club_management_app/features/reservations/domain/usecases/load_upcoming_reservations_use_case.dart';
import 'package:club_management_app/features/reservations/domain/usecases/watch_reservation_changes_use_case.dart';
import 'package:club_management_app/features/reservations/presentation/cubit/upcoming_reservations_cubit.dart';
import 'package:club_management_app/features/reservations/presentation/cubit/upcoming_reservations_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLoadClubUseCase extends Mock implements LoadClubUseCase {}

class MockLoadUpcomingReservationsUseCase extends Mock
    implements LoadUpcomingReservationsUseCase {}

class MockWatchReservationChangesUseCase extends Mock
    implements WatchReservationChangesUseCase {}

class MockWatchRosterChangesUseCase extends Mock
    implements WatchRosterChangesUseCase {}

void main() {
  final now = DateTime(2026, 11, 13, 17, 30);
  final today = DateTime(2026, 11, 13);
  const court = Court(
    id: 1,
    name: 'Cancha de Pádel 1',
    openingTime: ClockTime(8, 0),
    closingTime: ClockTime(23, 0),
    isActive: true,
  );
  const roster = [
    Member(
      id: 1,
      firstName: 'Marcos',
      lastName: 'Gómez',
      dni: '30111222',
      status: MemberStatus.active,
      daysOverdue: 0,
    ),
  ];
  late MockLoadClubUseCase loadClub;
  late MockLoadUpcomingReservationsUseCase loadUpcoming;
  late StreamController<void> changes;
  late StreamController<void> rosterChanges;

  Club club({required bool courtsEnabled}) =>
      Club(id: 1, name: 'Club 1', courtsEnabled: courtsEnabled);

  Reservation at(int id, int hour) => Reservation(
        id: id,
        courtId: 1,
        memberId: 1,
        date: today,
        startTime: ClockTime(hour, 0),
        endTime: ClockTime(hour + 1, 0),
      );

  UpcomingReservations upcomingOf(
    List<Reservation> reservations, {
    List<Member>? roster,
  }) =>
      UpcomingReservations(
        items: [
          for (final reservation in reservations)
            UpcomingReservation(reservation: reservation, court: court),
        ],
        roster: roster,
      );

  void answerWith(UpcomingReservations Function(List<Member>?) answer) {
    when(
      () => loadUpcoming(
        now,
        limit: UpcomingReservationsCubit.shownReservations,
        knownMembers: any(named: 'knownMembers'),
      ),
    ).thenAnswer(
      (invocation) async => Right(
        answer(invocation.namedArguments[#knownMembers] as List<Member>?),
      ),
    );
  }

  UpcomingReservationsCubit build() {
    final watch = MockWatchReservationChangesUseCase();
    when(watch.call).thenAnswer((_) => changes.stream);
    final watchRoster = MockWatchRosterChangesUseCase();
    when(watchRoster.call).thenAnswer((_) => rosterChanges.stream);

    return UpcomingReservationsCubit(
      loadClub: loadClub,
      loadUpcoming: loadUpcoming,
      watchReservations: watch,
      watchRoster: watchRoster,
      clock: () => now,
    );
  }


  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    loadClub = MockLoadClubUseCase();
    loadUpcoming = MockLoadUpcomingReservationsUseCase();
    changes = StreamController<void>.broadcast();
    rosterChanges = StreamController<void>.broadcast();
  });

  tearDown(() async {
    await changes.close();
    await rosterChanges.close();
  });

  test('stays hidden when the club has no courts', () async {
    when(loadClub.call)
        .thenAnswer((_) async => Right(club(courtsEnabled: false)));
    final cubit = build();

    await cubit.load();

    expect(cubit.state, const UpcomingReservationsHidden());
    verifyNever(
      () => loadUpcoming(
        any(),
        limit: any(named: 'limit'),
        knownMembers: any(named: 'knownMembers'),
      ),
    );
    await cubit.close();
  });

  test('shows the upcoming reservations of the day', () async {
    when(loadClub.call)
        .thenAnswer((_) async => Right(club(courtsEnabled: true)));
    final upcoming = upcomingOf([at(2, 17), at(3, 18)], roster: roster);
    answerWith((_) => upcoming);
    final cubit = build();

    await cubit.load();

    expect(cubit.state, UpcomingReservationsReady(upcoming));
    await cubit.close();
  });

  test('reports a failure to load the day', () async {
    when(loadClub.call)
        .thenAnswer((_) async => Right(club(courtsEnabled: true)));
    when(
      () => loadUpcoming(
        now,
        limit: UpcomingReservationsCubit.shownReservations,
        knownMembers: any(named: 'knownMembers'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    final cubit = build();

    await cubit.load();

    expect(
      cubit.state,
      const UpcomingReservationsFailure(isOffline: true),
    );
    await cubit.close();
  });

  test('reuses the roster between reloads, rereads it on refresh', () async {
    when(loadClub.call)
        .thenAnswer((_) async => Right(club(courtsEnabled: true)));
    final asked = <List<Member>?>[];
    answerWith((known) {
      asked.add(known);
      return upcomingOf([at(1, 18)], roster: known ?? roster);
    });
    final cubit = build();

    await cubit.load();
    await cubit.load();
    await cubit.refresh();

    expect(asked, [null, roster, null]);
    await cubit.close();
  });

  test('keeps asking for the roster while no load needed it', () async {
    when(loadClub.call)
        .thenAnswer((_) async => Right(club(courtsEnabled: true)));
    final asked = <List<Member>?>[];
    answerWith((known) {
      asked.add(known);
      return upcomingOf(const []);
    });
    final cubit = build();

    await cubit.load();
    await cubit.load();

    expect(asked, [null, null]);
    await cubit.close();
  });
}
