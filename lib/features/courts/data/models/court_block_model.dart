import '../../domain/entities/court_block.dart';
import '../../domain/entities/court_block_draft.dart';

class CourtBlockModel extends CourtBlock {
  const CourtBlockModel({
    required super.id,
    required super.courtId,
    required super.startsAt,
    required super.endsAt,
    super.reason,
  });

  static const String _idKey = 'id';
  static const String _courtIdKey = 'courtId';
  static const String _startsAtKey = 'startsAt';
  static const String _endsAtKey = 'endsAt';
  static const String _reasonKey = 'reason';
  static const String _reservationIdsToCancelKey = 'reservationIdsToCancel';

  factory CourtBlockModel.fromJson(Map<String, dynamic> json) {
    return CourtBlockModel(
      id: (json[_idKey] as num).toInt(),
      courtId: (json[_courtIdKey] as num).toInt(),
      startsAt: DateTime.parse(json[_startsAtKey] as String),
      endsAt: DateTime.parse(json[_endsAtKey] as String),
      reason: json[_reasonKey] as String?,
    );
  }

  static Map<String, dynamic> bodyFromDraft(CourtBlockDraft draft) {
    return {
      _startsAtKey: localDateTimeToJson(draft.startsAt),
      _endsAtKey: localDateTimeToJson(draft.endsAt),
      _reasonKey: draft.reason.isEmpty ? null : draft.reason,
      _reservationIdsToCancelKey: draft.reservationIdsToCancel,
    };
  }

  static String localDateTimeToJson(DateTime value) {
    final time = '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';

    return '${dayToJson(value)}T$time';
  }

  static String dayToJson(DateTime day) =>
      '${day.year}-${_twoDigits(day.month)}-${_twoDigits(day.day)}';

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
