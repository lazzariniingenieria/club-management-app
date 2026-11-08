import 'package:equatable/equatable.dart';

class ClockTime extends Equatable implements Comparable<ClockTime> {
  final int hour;
  final int minute;

  const ClockTime(this.hour, this.minute)
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);

  static const ClockTime lastMinuteOfDay = ClockTime(23, 59);

  int get minutesOfDay => hour * Duration.minutesPerHour + minute;

  bool isAfter(ClockTime other) => minutesOfDay > other.minutesOfDay;

  @override
  int compareTo(ClockTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  @override
  List<Object?> get props => [hour, minute];
}
