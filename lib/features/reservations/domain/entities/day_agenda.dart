import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/court.dart';
import '../../../courts/domain/entities/court_block.dart';
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

  CourtAgenda? agendaOf(int courtId) {
    for (final agenda in courts) {
      if (agenda.court.id == courtId) return agenda;
    }

    return null;
  }

  @override
  List<Object?> get props => [day, courts, members];
}
