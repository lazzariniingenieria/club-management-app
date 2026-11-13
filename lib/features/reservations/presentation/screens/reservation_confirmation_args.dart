import '../../../courts/domain/entities/court.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/reservation_draft.dart';

class ReservationConfirmationArgs {
  final ReservationDraft draft;
  final Court court;
  final Member member;

  const ReservationConfirmationArgs({
    required this.draft,
    required this.court,
    required this.member,
  });
}
