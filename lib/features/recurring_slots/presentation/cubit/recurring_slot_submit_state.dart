import 'package:equatable/equatable.dart';

import '../../domain/entities/recurring_slot_clash.dart';

sealed class RecurringSlotSubmitState extends Equatable {
  const RecurringSlotSubmitState();

  @override
  List<Object?> get props => [];
}

class RecurringSlotSubmitIdle extends RecurringSlotSubmitState {
  const RecurringSlotSubmitIdle();
}

class RecurringSlotSubmitting extends RecurringSlotSubmitState {
  const RecurringSlotSubmitting();
}

class RecurringSlotSubmitSaved extends RecurringSlotSubmitState {
  const RecurringSlotSubmitSaved();
}

class RecurringSlotSubmitClashes extends RecurringSlotSubmitState {
  final List<RecurringSlotClash> clashes;

  const RecurringSlotSubmitClashes(this.clashes);

  @override
  List<Object?> get props => [clashes];
}

class RecurringSlotSubmitFailure extends RecurringSlotSubmitState {
  final String message;

  const RecurringSlotSubmitFailure(this.message);

  @override
  List<Object?> get props => [message];
}
