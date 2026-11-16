import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../courts/domain/entities/court.dart';
import '../../../courts/domain/repositories/court_repository.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../entities/reservation.dart';
import '../entities/upcoming_reservations.dart';
import '../repositories/reservation_repository.dart';

class LoadUpcomingReservationsUseCase {
  final CourtRepository courts;
  final ReservationRepository reservations;
  final MemberRepository members;

  LoadUpcomingReservationsUseCase({
    required this.courts,
    required this.reservations,
    required this.members,
  });

  Future<Either<Failure, UpcomingReservations>> call(
    DateTime now, {
    required int limit,
    List<Member>? knownMembers,
  }) async {
    final results = await Future.wait<Object>([
      courts.loadCourts(),
      reservations.loadReservations(DateTime(now.year, now.month, now.day)),
    ]);
    final courtList = results[0] as Either<Failure, List<Court>>;
    final reservationList = results[1] as Either<Failure, List<Reservation>>;
    final failure = courtList.getLeft().toNullable() ??
        reservationList.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final upcoming = UpcomingReservations(
      items: _pendingOf(
        courtList.getRight().toNullable()!,
        reservationList.getRight().toNullable()!,
        now,
      ).take(limit).toList(),
      roster: knownMembers,
    );

    return _withRoster(upcoming);
  }

  Future<Either<Failure, UpcomingReservations>> _withRoster(
    UpcomingReservations upcoming,
  ) async {
    if (upcoming.roster != null || !upcoming.needsRoster) {
      return Right(upcoming);
    }

    final roster = await members.loadMembers();

    return roster.map(
      (list) => UpcomingReservations(items: upcoming.items, roster: list),
    );
  }

  static List<UpcomingReservation> _pendingOf(
    List<Court> courtList,
    List<Reservation> reservationList,
    DateTime now,
  ) {
    final activeById = {
      for (final court in courtList)
        if (court.isActive) court.id: court,
    };

    final pending = [
      for (final reservation in reservationList)
        if (activeById[reservation.courtId] case final court?)
          UpcomingReservation(reservation: reservation, court: court),
    ];

    return [
      for (final item in pending)
        if (item.endsAt.isAfter(now)) item,
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }
}
