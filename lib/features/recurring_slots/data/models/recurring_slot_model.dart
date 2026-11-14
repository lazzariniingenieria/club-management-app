import '../../../courts/data/models/court_block_model.dart';
import '../../../courts/data/models/court_model.dart';
import '../../domain/entities/recurring_slot.dart';
import '../../domain/entities/recurring_slot_clash.dart';
import '../../domain/entities/recurring_slot_draft.dart';
import '../../domain/entities/recurring_slot_validity.dart';

class RecurringSlotModel extends RecurringSlot {
  const RecurringSlotModel({
    required super.id,
    required super.courtId,
    required super.weekday,
    required super.startTime,
    required super.endTime,
    required super.validFrom,
    required super.validUntil,
    required super.state,
    super.memberId,
    super.description,
  });

  static const String _idKey = 'id';
  static const String _courtIdKey = 'courtId';
  static const String _memberIdKey = 'memberId';
  static const String _descriptionKey = 'description';
  static const String _dayOfWeekKey = 'dayOfWeek';
  static const String _startTimeKey = 'startTime';
  static const String _endTimeKey = 'endTime';
  static const String _validFromKey = 'validFrom';
  static const String _validUntilKey = 'validUntil';
  static const String _stateKey = 'state';

  static const List<String> _daysOfWeek = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  static const Map<String, RecurringSlotState> _states = {
    'CURRENT': RecurringSlotState.current,
    'EXPIRED': RecurringSlotState.expired,
    'INACTIVE': RecurringSlotState.inactive,
  };

  factory RecurringSlotModel.fromJson(Map<String, dynamic> json) {
    return RecurringSlotModel(
      id: (json[_idKey] as num).toInt(),
      courtId: (json[_courtIdKey] as num).toInt(),
      memberId: (json[_memberIdKey] as num?)?.toInt(),
      description: json[_descriptionKey] as String?,
      weekday: weekdayFromJson(json[_dayOfWeekKey] as String),
      startTime: CourtModel.clockTimeFromJson(json[_startTimeKey] as String),
      endTime: CourtModel.clockTimeFromJson(json[_endTimeKey] as String),
      validFrom: DateTime.parse(json[_validFromKey] as String),
      validUntil: DateTime.parse(json[_validUntilKey] as String),
      state: _stateFromJson(json[_stateKey] as String),
    );
  }

  static int weekdayFromJson(String value) {
    final index = _daysOfWeek.indexOf(value);
    if (index < 0) throw FormatException('Unknown day of week $value');

    return index + DateTime.monday;
  }

  static String weekdayToJson(int weekday) =>
      _daysOfWeek[weekday - DateTime.monday];

  static RecurringSlotState _stateFromJson(String value) {
    final state = _states[value];
    if (state == null) throw FormatException('Unknown state $value');

    return state;
  }

  static Map<String, dynamic> bodyFromDraft(RecurringSlotDraft draft) {
    final description = draft.description?.trim();

    return {
      _courtIdKey: draft.courtId,
      _memberIdKey: draft.memberId,
      _descriptionKey:
          description == null || description.isEmpty ? null : description,
      _dayOfWeekKey: weekdayToJson(draft.weekday),
      _startTimeKey: CourtModel.clockTimeToJson(draft.startTime),
      _endTimeKey: CourtModel.clockTimeToJson(draft.endTime),
      ...bodyFromValidity(draft.validity),
    };
  }

  static Map<String, dynamic> bodyFromValidity(RecurringSlotValidity validity) {
    return {
      _validFromKey: CourtBlockModel.dayToJson(validity.from),
      _validUntilKey: CourtBlockModel.dayToJson(validity.until),
    };
  }

  static List<RecurringSlotClash> clashesFromDetails(List<String> details) {
    return [
      for (final detail in details)
        if (_clashOf(detail) case final clash?) clash,
    ];
  }

  static RecurringSlotClash? _clashOf(String detail) {
    final separator = detail.indexOf(':');
    if (separator < 0) return null;

    final date = DateTime.tryParse(detail.substring(0, separator).trim());
    if (date == null) return null;

    return RecurringSlotClash(date: date, reason: _reasonOf(detail));
  }

  static ClashReason _reasonOf(String detail) {
    if (detail.contains('blocked')) return ClashReason.blocked;
    if (detail.contains('reserved')) return ClashReason.reserved;

    return ClashReason.unknown;
  }
}
