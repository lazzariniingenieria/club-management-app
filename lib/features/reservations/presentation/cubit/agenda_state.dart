import 'package:equatable/equatable.dart';

import '../../domain/entities/day_agenda.dart';

sealed class AgendaState extends Equatable {
  final DateTime day;

  const AgendaState(this.day);

  @override
  List<Object?> get props => [day];
}

class AgendaLoading extends AgendaState {
  const AgendaLoading(super.day);
}

class AgendaReady extends AgendaState {
  final DayAgenda agenda;

  AgendaReady(this.agenda) : super(agenda.day);

  @override
  List<Object?> get props => [day, agenda];
}

class AgendaFailure extends AgendaState {
  final bool isOffline;

  const AgendaFailure(super.day, {required this.isOffline});

  @override
  List<Object?> get props => [day, isOffline];
}
