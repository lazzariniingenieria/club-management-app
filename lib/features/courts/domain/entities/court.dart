import 'package:equatable/equatable.dart';

import 'clock_time.dart';

class Court extends Equatable {
  final int id;
  final String name;
  final String? type;
  final ClockTime openingTime;
  final ClockTime closingTime;
  final bool isActive;

  const Court({
    required this.id,
    required this.name,
    required this.openingTime,
    required this.closingTime,
    required this.isActive,
    this.type,
  });

  @override
  List<Object?> get props =>
      [id, name, type, openingTime, closingTime, isActive];
}
