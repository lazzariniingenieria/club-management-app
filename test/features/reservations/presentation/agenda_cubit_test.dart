import 'dart:async';

import 'package:club_management_app/features/courts/domain/repositories/court_block_repository.dart';
import 'package:club_management_app/features/courts/domain/repositories/court_repository.dart';
import 'package:club_management_app/features/courts/domain/usecases/watch_court_block_changes_use_case.dart';
import 'package:club_management_app/features/courts/domain/usecases/watch_court_changes_use_case.dart';
import 'package:club_management_app/features/members/domain/repositories/member_repository.dart';
import 'package:club_management_app/features/members/domain/usecases/watch_roster_changes_use_case.dart';
import 'package:club_management_app/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:club_management_app/features/reservations/domain/usecases/cancel_reservation_use_case.dart';
import 'package:club_management_app/features/reservations/domain/usecases/load_day_agenda_use_case.dart';
import 'package:club_management_app/features/reservations/domain/usecases/watch_reservation_changes_use_case.dart';
import 'package:club_management_app/features/reservations/presentation/cubit/agenda_cubit.dart';
import 'package:club_management_app/features/reservations/presentation/cubit/agenda_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCourtRepository extends Mock implements CourtRepository {}

class MockCourtBlockRepository extends Mock implements CourtBlockRepository {}

class MockReservationRepository extends Mock implements ReservationRepository {}

class MockMemberRepository extends Mock implements MemberRepository {}

void main() {
  final today = DateTime(2026, 11, 10);
  final tomorrow = DateTime(2026, 11, 11);
  final rosterChanges = StreamController<void>.broadcast();
  late MockReservationRepository reservations;
  late MockMemberRepository members;
  late AgendaCubit cubit;

  AgendaCubit buildCubit() {
    final courts = MockCourtRepository();
    final blocks = MockCourtBlockRepository();
    when(() => courts.courtChanges).thenAnswer((_) => const Stream.empty());
    when(() => blocks.blockChanges).thenAnswer((_) => const Stream.empty());
    when(() => courts.loadCourts()).thenAnswer((_) async => const Right([]));

    return AgendaCubit(
      loadAgenda: LoadDayAgendaUseCase(
        courts: courts,
        blocks: blocks,
        reservations: reservations,
        members: members,
      ),
      cancelReservation: CancelReservationUseCase(reservations),
      watchReservations: WatchReservationChangesUseCase(reservations),
      watchBlocks: WatchCourtBlockChangesUseCase(blocks),
      watchCourts: WatchCourtChangesUseCase(courts),
      watchRoster: WatchRosterChangesUseCase(members),
      clock: () => today,
    );
  }

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    reservations = MockReservationRepository();
    members = MockMemberRepository();
    when(() => reservations.reservationChanges)
        .thenAnswer((_) => const Stream.empty());
    when(() => reservations.loadReservations(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => members.rosterChanges).thenAnswer((_) => rosterChanges.stream);
    when(() => members.loadMembers()).thenAnswer((_) async => const Right([]));
    cubit = buildCubit();
  });

  tearDown(() => cubit.close());

  test('changing the agenda day does not reload the member roster', () async {
    await cubit.showDay(today);
    await cubit.showDay(tomorrow);

    expect(cubit.state, isA<AgendaReady>());
    expect(cubit.state.day, tomorrow);
    verify(() => members.loadMembers()).called(1);
  });

  test('a manual refresh reloads the member roster', () async {
    await cubit.showDay(today);
    await cubit.refresh();

    verify(() => members.loadMembers()).called(2);
  });

  test('a roster change reloads the member roster', () async {
    await cubit.showDay(today);
    rosterChanges.add(null);
    await pumpEventQueue();

    verify(() => members.loadMembers()).called(2);
  });
}
