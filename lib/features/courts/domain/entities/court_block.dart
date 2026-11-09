import 'package:equatable/equatable.dart';

class CourtBlock extends Equatable {
  final int id;
  final int courtId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? reason;

  const CourtBlock({
    required this.id,
    required this.courtId,
    required this.startsAt,
    required this.endsAt,
    this.reason,
  });

  bool get isWithinOneDay =>
      startsAt.year == endsAt.year &&
      startsAt.month == endsAt.month &&
      startsAt.day == endsAt.day;

  @override
  List<Object?> get props => [id, courtId, startsAt, endsAt, reason];
}
