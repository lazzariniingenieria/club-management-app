import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/court.dart';
import '../../../courts/domain/entities/court_block.dart';
import '../../../courts/domain/entities/court_block_draft.dart';
import '../../../members/domain/entities/member.dart';
import 'reservation.dart';

class CourtAgenda extends Equatable {
  final Court court;
  final List<Reservation> reservations;
  final List<CourtBlock> blocks;

  const CourtAgenda({
    required this.court,
    required this.reservations,
    required this.blocks,
  });

  @override
  List<Object?> get props => [court, reservations, blocks];
}

class DayAgenda extends Equatable {
  final DateTime day;
  final List<CourtAgenda> courts;
  final List<Member> members;

  const DayAgenda({
    required this.day,
    required this.courts,
    required this.members,
  });

  Member? memberOf(Reservation reservation) {
    for (final member in members) {
      if (member.id == reservation.memberId) return member;
    }

    return null;
  }

  List<UpcomingReservation> upcoming(DateTime now, {required int limit}) {
    final pending = [
      for (final courtAgenda in courts)
        for (final reservation in courtAgenda.reservations)
          if (_endOf(reservation).isAfter(now))
            UpcomingReservation(
              reservation: reservation,
              court: courtAgenda.court,
            ),
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return pending.take(limit).toList();
  }

  static DateTime _endOf(Reservation reservation) =>
      CourtBlockDraft.at(reservation.date, reservation.endTime);

  CourtAgenda? agendaOf(int courtId) {
    for (final agenda in courts) {
      if (agenda.court.id == courtId) return agenda;
    }

    return null;
  }

  @override
  List<Object?> get props => [day, courts, members];
}

class UpcomingReservation extends Equatable {
  final Reservation reservation;
  final Court court;

  const UpcomingReservation({required this.reservation, required this.court});

  DateTime get startsAt =>
      CourtBlockDraft.at(reservation.date, reservation.startTime);

  @override
  List<Object?> get props => [reservation, court];
}
