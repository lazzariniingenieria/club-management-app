import 'package:equatable/equatable.dart';

import '../../../courts/domain/entities/court.dart';
import '../../../courts/domain/entities/court_block_draft.dart';
import '../../../members/domain/entities/member.dart';
import 'reservation.dart';

class UpcomingReservation extends Equatable {
  final Reservation reservation;
  final Court court;

  const UpcomingReservation({required this.reservation, required this.court});

  DateTime get startsAt =>
      CourtBlockDraft.at(reservation.date, reservation.startTime);

  DateTime get endsAt =>
      CourtBlockDraft.at(reservation.date, reservation.endTime);

  @override
  List<Object?> get props => [reservation, court];
}

class UpcomingReservations extends Equatable {
  final List<UpcomingReservation> items;
  final List<Member>? roster;

  const UpcomingReservations({required this.items, this.roster});

  bool get needsRoster =>
      items.any((item) => item.reservation.memberId != null);

  Member? memberOf(Reservation reservation) {
    for (final member in roster ?? const <Member>[]) {
      if (member.id == reservation.memberId) return member;
    }

    return null;
  }

  @override
  List<Object?> get props => [items, roster];
}
