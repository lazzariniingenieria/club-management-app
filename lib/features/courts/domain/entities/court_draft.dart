import 'package:equatable/equatable.dart';

import 'clock_time.dart';
import 'court.dart';

class CourtDraft extends Equatable {
  static const ClockTime defaultOpeningTime = ClockTime(8, 0);
  static const ClockTime defaultClosingTime = ClockTime(23, 0);

  final String name;
  final String type;
  final ClockTime openingTime;
  final ClockTime closingTime;

  const CourtDraft({
    required this.name,
    this.type = '',
    this.openingTime = defaultOpeningTime,
    this.closingTime = defaultClosingTime,
  });

  factory CourtDraft.fromCourt(Court court) => CourtDraft(
        name: court.name,
        type: court.type ?? '',
        openingTime: court.openingTime,
        closingTime: court.closingTime,
      );

  bool get closesAfterOpening => closingTime.isAfter(openingTime);

  CourtDraft trimmed() => CourtDraft(
        name: name.trim(),
        type: type.trim(),
        openingTime: openingTime,
        closingTime: closingTime,
      );

  @override
  List<Object?> get props => [name, type, openingTime, closingTime];
}
