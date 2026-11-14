import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';

enum ClashReason { reserved, blocked, unknown }

class RecurringSlotClash extends Equatable {
  final DateTime date;
  final ClashReason reason;

  const RecurringSlotClash({required this.date, required this.reason});

  @override
  List<Object?> get props => [date, reason];
}

class RecurringSlotClashFailure extends ConflictFailure {
  final List<RecurringSlotClash> clashes;

  const RecurringSlotClashFailure(this.clashes)
      : super('Some dates of the recurring slot are taken');

  @override
  List<Object?> get props => [message, clashes];
}
