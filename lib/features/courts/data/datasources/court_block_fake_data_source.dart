import '../../../../core/errors/exceptions.dart';
import '../../../reservations/data/datasources/reservation_fake_data_source.dart';
import '../../domain/entities/court_block_draft.dart';
import '../models/court_block_model.dart';
import 'court_block_remote_data_source.dart';

class CourtBlockFakeDataSource implements CourtBlockRemoteDataSource {
  CourtBlockFakeDataSource({
    this.latency = const Duration(milliseconds: 600),
    DateTime Function() clock = DateTime.now,
    this.reservations,
  }) : _blocks = _seeded(clock());

  final Duration latency;
  final ReservationFakeDataSource? reservations;
  final List<CourtBlockModel> _blocks;

  static const int seededBlockId = 1;
  static const int seededCourtId = 1;
  static const String seededReason = 'Mantenimiento de superficie';

  static List<CourtBlockModel> _seeded(DateTime now) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return [
      CourtBlockModel(
        id: seededBlockId,
        courtId: seededCourtId,
        startsAt: tomorrow.add(const Duration(hours: 8)),
        endsAt: tomorrow.add(const Duration(hours: 12)),
        reason: seededReason,
      ),
    ];
  }

  @override
  Future<List<CourtBlockModel>> fetchBlocks(
    int courtId, {
    required DateTime from,
  }) async {
    await Future<void>.delayed(latency);

    return [
      for (final block in _blocks)
        if (block.courtId == courtId && block.endsAt.isAfter(from)) block,
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  Future<void> createBlock(int courtId, CourtBlockDraft draft) async {
    await Future<void>.delayed(latency);
    if (!draft.endsAfterStarts) {
      throw ValidationException('endsAt must be after startsAt');
    }
    _cancelAffected(courtId, draft);

    _blocks.add(
      CourtBlockModel(
        id: _nextId(),
        courtId: courtId,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        reason: draft.reason.isEmpty ? null : draft.reason,
      ),
    );
  }

  void _cancelAffected(int courtId, CourtBlockDraft draft) {
    final affected = reservations?.affectedBy(courtId, draft) ?? const [];
    final notShown = [
      for (final reservation in affected)
        if (!draft.reservationIdsToCancel.contains(reservation.id))
          'reservation ${reservation.id}',
    ];
    if (notShown.isNotEmpty) {
      throw ConflictException('would cancel reservations not shown', notShown);
    }

    reservations?.cancelAll([for (final each in affected) each.id]);
  }

  @override
  Future<void> removeBlock(int courtId, int blockId) async {
    await Future<void>.delayed(latency);
    final index = _blocks.indexWhere(
      (block) => block.id == blockId && block.courtId == courtId,
    );
    if (index < 0) throw NotFoundException('Unknown court block $blockId');

    _blocks.removeAt(index);
  }

  int _nextId() {
    var highestId = 0;

    for (final block in _blocks) {
      if (block.id > highestId) highestId = block.id;
    }

    return highestId + 1;
  }
}
