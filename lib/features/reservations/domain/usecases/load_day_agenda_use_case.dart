import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../courts/domain/entities/court.dart';
import '../../../courts/domain/entities/court_block.dart';
import '../../../courts/domain/repositories/court_block_repository.dart';
import '../../../courts/domain/repositories/court_repository.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../entities/day_agenda.dart';
import '../entities/reservation.dart';
import '../repositories/reservation_repository.dart';

class LoadDayAgendaUseCase {
  final CourtRepository courts;
  final CourtBlockRepository blocks;
  final ReservationRepository reservations;
  final MemberRepository members;

  LoadDayAgendaUseCase({
    required this.courts,
    required this.blocks,
    required this.reservations,
    required this.members,
  });

  Future<Either<Failure, DayAgenda>> call(
    DateTime day, {
    List<Member>? knownMembers,
  }) async {
    final results = await Future.wait<Object>([
      courts.loadCourts(),
      reservations.loadReservations(day),
      _rosterOf(knownMembers),
    ]);
    final courtList = results[0] as Either<Failure, List<Court>>;
    final reservationList = results[1] as Either<Failure, List<Reservation>>;
    final roster = results[2] as Either<Failure, List<Member>>;
    final failure = _firstFailure([courtList, reservationList, roster]);
    if (failure != null) return Left(failure);

    final active = _activeOf(courtList.getRight().toNullable()!);
    final blocksByCourt = await Future.wait([
      for (final court in active) _blocksOfDay(court.id, day),
    ]);
    final blocksFailure = _firstFailure(blocksByCourt);
    if (blocksFailure != null) return Left(blocksFailure);

    return Right(
      DayAgenda(
        day: day,
        members: roster.getRight().toNullable()!,
        courts: _courtAgendas(
          active,
          reservationList.getRight().toNullable()!,
          blocksByCourt,
        ),
      ),
    );
  }

  Future<Either<Failure, List<Member>>> _rosterOf(List<Member>? knownMembers) {
    if (knownMembers == null) return members.loadMembers();

    return Future.value(Right(knownMembers));
  }

  Future<Either<Failure, List<CourtBlock>>> _blocksOfDay(
    int courtId,
    DateTime day,
  ) async {
    final nextDay = DateTime(day.year, day.month, day.day + 1);
    final result = await blocks.loadBlocks(courtId, from: day);

    return result.map(
      (all) => [
        for (final block in all)
          if (block.startsAt.isBefore(nextDay)) block,
      ],
    );
  }

  static List<Court> _activeOf(List<Court> courtList) => [
        for (final court in courtList)
          if (court.isActive) court,
      ];

  static List<CourtAgenda> _courtAgendas(
    List<Court> active,
    List<Reservation> reservationList,
    List<Either<Failure, List<CourtBlock>>> blocksByCourt,
  ) {
    return [
      for (var index = 0; index < active.length; index++)
        CourtAgenda(
          court: active[index],
          reservations: _ofCourt(reservationList, active[index].id),
          blocks: blocksByCourt[index].getRight().toNullable()!,
        ),
    ];
  }

  static List<Reservation> _ofCourt(List<Reservation> all, int courtId) => [
        for (final reservation in all)
          if (reservation.courtId == courtId) reservation,
      ]..sort((a, b) => a.startTime.compareTo(b.startTime));

  static Failure? _firstFailure(List<Either<Failure, Object>> results) {
    for (final result in results) {
      final failure = result.getLeft().toNullable();
      if (failure != null) return failure;
    }

    return null;
  }
}
