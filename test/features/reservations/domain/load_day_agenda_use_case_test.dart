import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court.dart';
import 'package:club_management_app/features/courts/domain/entities/court_block.dart';
import 'package:club_management_app/features/courts/domain/repositories/court_block_repository.dart';
import 'package:club_management_app/features/courts/domain/repositories/court_repository.dart';
import 'package:club_management_app/features/members/domain/repositories/member_repository.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:club_management_app/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:club_management_app/features/reservations/domain/usecases/load_day_agenda_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCourtRepository extends Mock implements CourtRepository {}

class MockCourtBlockRepository extends Mock implements CourtBlockRepository {}

class MockReservationRepository extends Mock implements ReservationRepository {}

class MockMemberRepository extends Mock implements MemberRepository {}

Court court(int id, {bool isActive = true}) => Court(
      id: id,
      name: 'Cancha $id',
      openingTime: const ClockTime(8, 0),
      closingTime: const ClockTime(23, 0),
      isActive: isActive,
    );

Reservation reservation(int id, int courtId, int hour) => Reservation(
      id: id,
      courtId: courtId,
      memberId: 1,
      date: DateTime(2026, 11, 10),
      startTime: ClockTime(hour, 0),
      endTime: ClockTime(hour + 1, 0),
    );

void main() {
  final day = DateTime(2026, 11, 10);
  late MockCourtRepository courts;
  late MockCourtBlockRepository blocks;
  late MockReservationRepository reservations;
  late MockMemberRepository members;
  late LoadDayAgendaUseCase loadAgenda;

  setUp(() {
    courts = MockCourtRepository();
    blocks = MockCourtBlockRepository();
    reservations = MockReservationRepository();
    members = MockMemberRepository();
    loadAgenda = LoadDayAgendaUseCase(
      courts: courts,
      blocks: blocks,
      reservations: reservations,
      members: members,
    );
    when(() => members.loadMembers()).thenAnswer((_) async => const Right([]));
  });

  test('groups the reservations of the day by active court, by hour', () async {
    when(() => courts.loadCourts()).thenAnswer(
      (_) async => Right([court(1), court(2), court(3, isActive: false)]),
    );
    when(() => reservations.loadReservations(day)).thenAnswer(
      (_) async => Right([
        reservation(10, 2, 19),
        reservation(11, 1, 9),
        reservation(12, 2, 8),
      ]),
    );
    when(() => blocks.loadBlocks(any(), from: day))
        .thenAnswer((_) async => const Right([]));

    final agenda = (await loadAgenda(day)).getRight().toNullable()!;

    expect(agenda.courts.map((each) => each.court.id), [1, 2]);
    expect(agenda.courts[1].reservations.map((each) => each.id), [12, 10]);
    verifyNever(() => blocks.loadBlocks(3, from: day));
  });

  test('keeps only the blocks that start before the day ends', () async {
    when(() => courts.loadCourts()).thenAnswer((_) async => Right([court(1)]));
    when(() => reservations.loadReservations(day))
        .thenAnswer((_) async => const Right([]));
    when(() => blocks.loadBlocks(1, from: day)).thenAnswer(
      (_) async => Right([
        CourtBlock(
          id: 1,
          courtId: 1,
          startsAt: DateTime(2026, 11, 10, 8),
          endsAt: DateTime(2026, 11, 10, 12),
        ),
        CourtBlock(
          id: 2,
          courtId: 1,
          startsAt: DateTime(2026, 11, 11, 8),
          endsAt: DateTime(2026, 11, 11, 12),
        ),
      ]),
    );

    final agenda = (await loadAgenda(day)).getRight().toNullable()!;

    expect(agenda.courts.single.blocks.map((each) => each.id), [1]);
  });

  test('a failure loading the reservations fails the whole agenda', () async {
    when(() => courts.loadCourts()).thenAnswer((_) async => Right([court(1)]));
    when(() => reservations.loadReservations(day))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await loadAgenda(day);

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
  });
}
