import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court.dart';
import 'package:club_management_app/features/courts/domain/repositories/court_repository.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/repositories/member_repository.dart';
import 'package:club_management_app/features/reservations/domain/entities/reservation.dart';
import 'package:club_management_app/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:club_management_app/features/reservations/domain/entities/upcoming_reservations.dart';
import 'package:club_management_app/features/reservations/domain/usecases/load_upcoming_reservations_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCourtRepository extends Mock implements CourtRepository {}

class MockReservationRepository extends Mock implements ReservationRepository {}

class MockMemberRepository extends Mock implements MemberRepository {}

final today = DateTime(2026, 11, 13);

Court court(int id, {bool isActive = true}) => Court(
      id: id,
      name: 'Cancha $id',
      openingTime: const ClockTime(8, 0),
      closingTime: const ClockTime(23, 0),
      isActive: isActive,
    );

Reservation memberAt(int id, int courtId, int hour) => Reservation(
      id: id,
      courtId: courtId,
      memberId: 1,
      date: today,
      startTime: ClockTime(hour, 0),
      endTime: ClockTime(hour + 1, 0),
    );

Reservation activityAt(int id, int hour) => Reservation(
      id: id,
      courtId: 1,
      source: ReservationSource.activity,
      description: 'Escuelita',
      date: today,
      startTime: ClockTime(hour, 0),
      endTime: ClockTime(hour + 1, 0),
    );

const Member marcos = Member(
  id: 1,
  firstName: 'Marcos',
  lastName: 'Gómez',
  dni: '30111222',
  status: MemberStatus.active,
  daysOverdue: 0,
);

void main() {
  late MockCourtRepository courts;
  late MockReservationRepository reservations;
  late MockMemberRepository members;
  late LoadUpcomingReservationsUseCase loadUpcoming;

  void dayWith(List<Reservation> reservationList) {
    when(() => reservations.loadReservations(today))
        .thenAnswer((_) async => Right(reservationList));
  }

  List<int> idsOf(Either<Failure, UpcomingReservations> result) => [
        for (final item in result.getRight().toNullable()!.items)
          item.reservation.id,
      ];

  setUp(() {
    courts = MockCourtRepository();
    reservations = MockReservationRepository();
    members = MockMemberRepository();
    loadUpcoming = LoadUpcomingReservationsUseCase(
      courts: courts,
      reservations: reservations,
      members: members,
    );
    when(() => courts.loadCourts())
        .thenAnswer((_) async => Right([court(1), court(2)]));
    when(() => members.loadMembers())
        .thenAnswer((_) async => const Right([marcos]));
  });

  test('lists the ones not finished yet, across courts, by start', () async {
    dayWith([memberAt(1, 1, 9), memberAt(2, 1, 18), memberAt(3, 2, 10)]);

    final result = await loadUpcoming(DateTime(2026, 11, 13, 10, 30), limit: 3);

    expect(idsOf(result), [3, 2]);
  });

  test('keeps only the first ones up to the limit', () async {
    dayWith([
      memberAt(1, 1, 9),
      memberAt(2, 1, 11),
      memberAt(3, 2, 12),
      memberAt(4, 2, 13),
    ]);

    final result = await loadUpcoming(DateTime(2026, 11, 13, 8), limit: 3);

    expect(idsOf(result), [1, 2, 3]);
  });

  test('leaves out the reservations of inactive courts', () async {
    when(() => courts.loadCourts())
        .thenAnswer((_) async => Right([court(1), court(2, isActive: false)]));
    dayWith([memberAt(1, 2, 9), memberAt(2, 1, 10)]);

    final result = await loadUpcoming(DateTime(2026, 11, 13, 8), limit: 3);

    expect(idsOf(result), [2]);
  });

  test('a day without reservations never asks for the roster', () async {
    dayWith(const []);

    final result = await loadUpcoming(DateTime(2026, 11, 13, 8), limit: 3);

    expect(result.getRight().toNullable()!.items, isEmpty);
    verifyNever(() => members.loadMembers());
  });

  test('only activities ahead never ask for the roster', () async {
    dayWith([memberAt(1, 1, 9), activityAt(2, 18)]);

    final result = await loadUpcoming(DateTime(2026, 11, 13, 12), limit: 3);

    expect(idsOf(result), [2]);
    expect(result.getRight().toNullable()!.roster, isNull);
    verifyNever(() => members.loadMembers());
  });

  test('a member reservation ahead loads the roster once and reuses it',
      () async {
    dayWith([memberAt(1, 1, 18)]);
    final now = DateTime(2026, 11, 13, 8);

    final first = (await loadUpcoming(now, limit: 3)).getRight().toNullable()!;
    final second = await loadUpcoming(
      now,
      limit: 3,
      knownMembers: first.roster,
    );

    expect(first.memberOf(first.items.single.reservation), marcos);
    expect(second.getRight().toNullable()!.roster, [marcos]);
    verify(() => members.loadMembers()).called(1);
  });

  test('a failure loading the reservations fails the whole load', () async {
    when(() => reservations.loadReservations(today))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await loadUpcoming(DateTime(2026, 11, 13, 8), limit: 3);

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
  });

  test('a failure loading the roster fails the load', () async {
    dayWith([memberAt(1, 1, 18)]);
    when(() => members.loadMembers())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await loadUpcoming(DateTime(2026, 11, 13, 8), limit: 3);

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
  });
}
