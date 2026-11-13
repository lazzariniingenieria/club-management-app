import 'package:flutter/material.dart';

import '../../domain/entities/clock_time.dart';
import '../formatting/court_formats.dart';

class CourtTimeField extends StatelessWidget {
  final String label;
  final ClockTime initialValue;
  final List<ClockTime> options;
  final ValueChanged<ClockTime> onChanged;
  final FormFieldValidator<ClockTime>? validator;

  const CourtTimeField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.options,
    required this.onChanged,
    this.validator,
  });

  static const int _stepMinutes = 30;
  static const double _menuMaxHeight = 320;
  static const ClockTime _midnight = ClockTime(0, 0);

  static List<ClockTime> openingOptions(ClockTime current) =>
      _withCurrent(_halfHours(), current);

  static List<ClockTime> closingOptions(ClockTime current) {
    final afterMidnight = _halfHours().where((time) => time != _midnight);

    return _withCurrent(
      [...afterMidnight, ClockTime.lastMinuteOfDay],
      current,
    );
  }

  static List<ClockTime> _halfHours() => [
        for (var minutes = 0;
            minutes < Duration.minutesPerDay;
            minutes += _stepMinutes)
          ClockTime(
            minutes ~/ Duration.minutesPerHour,
            minutes % Duration.minutesPerHour,
          ),
      ];

  static List<ClockTime> _withCurrent(
    List<ClockTime> options,
    ClockTime current,
  ) {
    if (options.contains(current)) return options;

    return [...options, current]..sort();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ClockTime>(
      initialValue: initialValue,
      menuMaxHeight: _menuMaxHeight,
      autovalidateMode: AutovalidateMode.always,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.schedule_rounded),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(CourtFormats.time(option)),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
