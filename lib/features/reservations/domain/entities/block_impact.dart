import 'package:equatable/equatable.dart';

import '../../../members/domain/entities/member.dart';
import 'reservation.dart';

class BlockImpact extends Equatable {
  final List<Reservation> reservations;
  final List<Member> members;

  const BlockImpact({required this.reservations, required this.members});

  static const BlockImpact none = BlockImpact(reservations: [], members: []);

  bool get cancelsNothing => reservations.isEmpty;

  List<int> get reservationIds => [
        for (final reservation in reservations) reservation.id,
      ];

  Member? memberOf(Reservation reservation) {
    for (final member in members) {
      if (member.id == reservation.memberId) return member;
    }

    return null;
  }

  @override
  List<Object?> get props => [reservations, members];
}
