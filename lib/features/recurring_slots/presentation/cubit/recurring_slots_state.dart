import 'package:equatable/equatable.dart';

import '../../domain/entities/recurring_slot_overview.dart';

sealed class RecurringSlotsState extends Equatable {
  const RecurringSlotsState();

  @override
  List<Object?> get props => [];
}

class RecurringSlotsLoading extends RecurringSlotsState {
  const RecurringSlotsLoading();
}

class RecurringSlotsReady extends RecurringSlotsState {
  final RecurringSlotOverview overview;

  const RecurringSlotsReady(this.overview);

  @override
  List<Object?> get props => [overview];
}

class RecurringSlotsFailure extends RecurringSlotsState {
  final bool isOffline;

  const RecurringSlotsFailure({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}
