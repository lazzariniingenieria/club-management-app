import '../../../courts/data/models/court_block_model.dart';
import '../../../courts/data/models/court_model.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/reservation_draft.dart';

class ReservationModel extends Reservation {
  const ReservationModel({
    required super.id,
    required super.courtId,
    required super.date,
    required super.startTime,
    required super.endTime,
    super.memberId,
    super.source,
    super.recurringSlotId,
    super.description,
  });

  static const String _idKey = 'id';
  static const String _courtIdKey = 'courtId';
  static const String _memberIdKey = 'memberId';
  static const String _sourceKey = 'source';
  static const String _recurringSlotIdKey = 'recurringSlotId';
  static const String _descriptionKey = 'description';
  static const String _dateKey = 'date';
  static const String _startTimeKey = 'startTime';
  static const String _endTimeKey = 'endTime';

  static const Map<String, ReservationSource> _sources = {
    'MEMBER': ReservationSource.member,
    'RECURRING': ReservationSource.recurring,
    'ACTIVITY': ReservationSource.activity,
  };

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: (json[_idKey] as num).toInt(),
      courtId: (json[_courtIdKey] as num).toInt(),
      memberId: (json[_memberIdKey] as num?)?.toInt(),
      source: sourceFromJson(json[_sourceKey] as String?),
      recurringSlotId: (json[_recurringSlotIdKey] as num?)?.toInt(),
      description: json[_descriptionKey] as String?,
      date: DateTime.parse(json[_dateKey] as String),
      startTime: CourtModel.clockTimeFromJson(json[_startTimeKey] as String),
      endTime: CourtModel.clockTimeFromJson(json[_endTimeKey] as String),
    );
  }

  static ReservationSource sourceFromJson(String? value) =>
      _sources[value] ?? ReservationSource.member;

  static Map<String, dynamic> bodyFromDraft(ReservationDraft draft) {
    return {
      _courtIdKey: draft.courtId,
      _memberIdKey: draft.memberId,
      _dateKey: CourtBlockModel.dayToJson(draft.date),
      _startTimeKey: CourtModel.clockTimeToJson(draft.startTime),
      _endTimeKey: CourtModel.clockTimeToJson(draft.endTime),
    };
  }
}
