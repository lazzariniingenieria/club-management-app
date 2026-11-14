import 'dart:async';

import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/club/domain/entities/club.dart';
import 'package:club_management_app/features/club/domain/usecases/load_club_use_case.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/usecases/watch_roster_changes_use_case.dart';
import 'package:club_management_app/features/reservations/domain/entities/day_agenda.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:club_management_app/features/reservations/domain/usecases/load_day_agenda_use_case.dart';
import 'package:club_management_app/features/reservations/domain/usecases/watch_reservation_changes_use_case.dart';
import 'package:club_management_app/features/reservations/presentation/cubit/upcoming_reservations_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLoadClubUseCase extends Mock implements LoadClubUseCase {}

class MockLoadDayAgendaUseCase extends Mock implements LoadDayAgendaUseCase {}

class MockWatchReservationChangesUseCase extends Mock
    implements WatchReservationChangesUseCase {}

class MockWatchRosterChangesUseCase extends Mock
    implements WatchRosterChangesUseCase {}

void main() {
  final now = DateTime(2026, 11, 13, 17, 30);
  final today = DateTime(2026, 11, 13);
  late MockLoadClubUseCase loadClub;
  late MockLoadDayAgendaUseCase loadAgenda;
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

  DayAgenda agendaOf(List<Reservation> reservations) => DayAgenda(
        day: today,
        members: const [],
        courts: [
          CourtAgenda(
            court: const Court(
              id: 1,
              name: 'Cancha de Pádel 1',
              openingTime: ClockTime(8, 0),
              closingTime: ClockTime(23, 0),
              isActive: true,
            ),
            reservations: reservations,
            blocks: const [],
          ),
        ],
      );

  UpcomingReservationsCubit build() {
    final watch = MockWatchReservationChangesUseCase();
    when(watch.call).thenAnswer((_) => changes.stream);
    final watchRoster = MockWatchRosterChangesUseCase();
    when(watchRoster.call).thenAnswer((_) => rosterChanges.stream);

    return UpcomingReservationsCubit(
      loadClub: loadClub,
      loadAgenda: loadAgenda,
      watchReservations: watch,
      watchRoster: watchRoster,
      clock: () => now,
    );
  }

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    loadClub = MockLoadClubUseCase();
    loadAgenda = MockLoadDayAgendaUseCase();
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
    verifyNever(() => loadAgenda(any()));
    await cubit.close();
  });

  test('shows the next three of today that did not end', () async {
    when(loadClub.call)
        .thenAnswer((_) async => Right(club(courtsEnabled: true)));
    final agenda = agendaOf(
      [at(1, 9), at(2, 17), at(3, 18), at(4, 19), at(5, 20)],
    );
    when(() => loadAgenda(today, knownMembers: any(named: 'knownMembers')))
        .thenAnswer((_) async => Right(agenda));
    final cubit = build();

    await cubit.load();

    final state = cubit.state as UpcomingReservationsReady;
    expect(
      [for (final item in state.upcoming) item.reservation.id],
      [2, 3, 4],
    );
    await cubit.close();
  });

  test('reports a failure to load the day', () async {
    when(loadClub.call)
        .thenAnswer((_) async => Right(club(courtsEnabled: true)));
    when(() => loadAgenda(today, knownMembers: any(named: 'knownMembers')))
        .thenAnswer((_) async => const Left(NetworkFailure()));
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
    final agenda = agendaOf([at(1, 18)]);
    final asked = <List<Member>?>[];
    when(() => loadAgenda(today, knownMembers: any(named: 'knownMembers')))
        .thenAnswer((invocation) async {
      asked.add(invocation.namedArguments[#knownMembers] as List<Member>?);
      return Right(agenda);
    });
    final cubit = build();

    await cubit.load();
    await cubit.load();
    await cubit.refresh();

    expect(asked, [null, agenda.members, null]);
    await cubit.close();
  });
}
