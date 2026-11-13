import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/clock_time.dart';
import '../../domain/entities/court_draft.dart';
import '../models/court_model.dart';
import 'court_remote_data_source.dart';

class CourtFakeDataSource implements CourtRemoteDataSource {
  CourtFakeDataSource({this.latency = const Duration(milliseconds: 600)})
      : _courts = [...seeded];

  final Duration latency;
  final List<CourtModel> _courts;

  static const List<CourtModel> seeded = [
    CourtModel(
      id: 1,
      name: 'Cancha de Pádel 1',
      type: 'Pádel',
      openingTime: ClockTime(8, 0),
      closingTime: ClockTime(23, 0),
      isActive: true,
    ),
    CourtModel(
      id: 2,
      name: 'Cancha de Tenis 1',
      type: 'Tenis',
      openingTime: ClockTime(8, 0),
      closingTime: ClockTime(22, 0),
      isActive: true,
    ),
    CourtModel(
      id: 3,
      name: 'Cancha de Fútbol 5',
      openingTime: ClockTime(9, 0),
      closingTime: ClockTime(23, 30),
      isActive: false,
    ),
  ];

  @override
  Future<List<CourtModel>> fetchCourts() async {
    await Future<void>.delayed(latency);

    return [..._courts];
  }

  @override
  Future<void> createCourt(CourtDraft draft) async {
    await Future<void>.delayed(latency);
    _rejectInvalid(draft);

    _courts.add(_fromDraft(_nextId(), draft, isActive: true));
  }

  @override
  Future<void> updateCourt(int courtId, CourtDraft draft) async {
    await Future<void>.delayed(latency);
    _rejectInvalid(draft, keeping: courtId);

    final index = _indexOf(courtId);
    _courts[index] =
        _fromDraft(courtId, draft, isActive: _courts[index].isActive);
  }

  @override
  Future<void> setCourtActive(int courtId, {required bool isActive}) async {
    await Future<void>.delayed(latency);
    final index = _indexOf(courtId);

    _courts[index] = _fromDraft(
      courtId,
      CourtDraft.fromCourt(_courts[index]),
      isActive: isActive,
    );
  }

  static CourtModel _fromDraft(
    int id,
    CourtDraft draft, {
    required bool isActive,
  }) {
    return CourtModel(
      id: id,
      name: draft.name,
      type: draft.type.isEmpty ? null : draft.type,
      openingTime: draft.openingTime,
      closingTime: draft.closingTime,
      isActive: isActive,
    );
  }

  void _rejectInvalid(CourtDraft draft, {int? keeping}) {
    if (!draft.closesAfterOpening) {
      throw ValidationException('closingTime must be after openingTime');
    }

    final name = draft.name.toLowerCase();
    for (final court in _courts.where((court) => court.id != keeping)) {
      if (court.name.toLowerCase() == name) {
        throw ConflictException('court name already in use');
      }
    }
  }

  int _indexOf(int courtId) {
    final index = _courts.indexWhere((court) => court.id == courtId);
    if (index < 0) throw NotFoundException('Unknown court $courtId');

    return index;
  }

  int _nextId() {
    var highestId = 0;

    for (final court in _courts) {
      if (court.id > highestId) highestId = court.id;
    }

    return highestId + 1;
  }
}
