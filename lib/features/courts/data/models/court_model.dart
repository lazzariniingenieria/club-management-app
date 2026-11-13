import '../../domain/entities/clock_time.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_draft.dart';

class CourtModel extends Court {
  const CourtModel({
    required super.id,
    required super.name,
    required super.openingTime,
    required super.closingTime,
    required super.isActive,
    super.type,
  });

  static const String _idKey = 'id';
  static const String _nameKey = 'name';
  static const String _typeKey = 'type';
  static const String _openingTimeKey = 'openingTime';
  static const String _closingTimeKey = 'closingTime';
  static const String _activeKey = 'active';

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      id: (json[_idKey] as num).toInt(),
      name: json[_nameKey] as String,
      type: json[_typeKey] as String?,
      openingTime: clockTimeFromJson(json[_openingTimeKey] as String),
      closingTime: clockTimeFromJson(json[_closingTimeKey] as String),
      isActive: json[_activeKey] as bool,
    );
  }

  static Map<String, dynamic> bodyFromDraft(CourtDraft draft) {
    return {
      _nameKey: draft.name,
      _typeKey: draft.type.isEmpty ? null : draft.type,
      _openingTimeKey: clockTimeToJson(draft.openingTime),
      _closingTimeKey: clockTimeToJson(draft.closingTime),
    };
  }

  static ClockTime clockTimeFromJson(String value) {
    final parts = value.split(':');

    return ClockTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  static String clockTimeToJson(ClockTime time) =>
      '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
