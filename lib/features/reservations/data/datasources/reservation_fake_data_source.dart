import '../../../../core/errors/exceptions.dart';
import '../../../courts/domain/entities/clock_time.dart';
import '../../domain/entities/reservation_draft.dart';
import '../models/reservation_model.dart';
import 'reservation_remote_data_source.dart';

class ReservationFakeDataSource implements ReservationRemoteDataSource {
  ReservationFakeDataSource({
    this.latency = const Duration(milliseconds: 600),
    DateTime Function() clock = DateTime.now,
  }) : _reservations = _seeded(clock());

  final Duration latency;
  final List<ReservationModel> _reservations;
  final Set<int> _cancelledIds = {};

  static const int seededReservationId = 1;
  static const int seededCourtId = 2;
  static const int seededMemberId = 2;
  static const ClockTime seededStart = ClockTime(19, 0);

  static List<ReservationModel> _seeded(DateTime now) {
    return [
      ReservationModel(
        id: seededReservationId,
        courtId: seededCourtId,
        memberId: seededMemberId,
        date: DateTime(now.year, now.month, now.day + 1),
        startTime: seededStart,
        endTime: const ClockTime(20, 0),
      ),
    ];
  }

  @override
  Future<List<ReservationModel>> fetchReservations(DateTime day) async {
    await Future<void>.delayed(latency);

    return [
      for (final reservation in _reservations)
        if (_sameDay(reservation.date, day)) reservation,
    ];
  }

  @override
  Future<void> createReservation(ReservationDraft draft) async {
    await Future<void>.delayed(latency);
    final taken = _reservations.any(
      (each) =>
          each.courtId == draft.courtId &&
          _sameDay(each.date, draft.date) &&
          each.overlaps(draft.startTime, draft.endTime),
    );
    if (taken) throw ConflictException('court already reserved at that time');

    _reservations.add(_fromDraft(_nextId(), draft));
  }

  @override
  Future<void> cancelReservation(int reservationId) async {
    await Future<void>.delayed(latency);
    if (_cancelledIds.contains(reservationId)) {
      throw ConflictException('Reservation already cancelled');
    }
    final index = _reservations.indexWhere((each) => each.id == reservationId);
    if (index < 0) throw NotFoundException('Unknown reservation');

    _reservations.removeAt(index);
    _cancelledIds.add(reservationId);
  }

  static ReservationModel _fromDraft(int id, ReservationDraft draft) {
    return ReservationModel(
      id: id,
      courtId: draft.courtId,
      memberId: draft.memberId,
      date: draft.date,
      startTime: draft.startTime,
      endTime: draft.endTime,
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _nextId() {
    var highestId = 0;

    for (final reservation in _reservations) {
      if (reservation.id > highestId) highestId = reservation.id;
    }

    return highestId + 1;
  }
}
