import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/day_agenda.dart';
import '../../domain/usecases/load_day_agenda_use_case.dart';
import 'agenda_state.dart';

mixin DayAgendaLoader on Cubit<AgendaState> {
  List<Member>? _knownMembers;

  LoadDayAgendaUseCase get loadAgenda;

  static DateTime dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> load() => showDay(state.day);

  Future<void> refresh() {
    _knownMembers = null;

    return load();
  }

  Future<void> showDay(DateTime day) async {
    final target = dayOf(day);
    if (state is! AgendaReady || state.day != target) {
      emit(AgendaLoading(target));
    }

    final result = await loadAgenda(target, knownMembers: _knownMembers);
    if (isClosed || state.day != target) return;

    emit(result.fold<AgendaState>(
      (failure) => AgendaFailure(target, isOffline: failure is NetworkFailure),
      _ready,
    ));
  }

  AgendaState _ready(DayAgenda agenda) {
    _knownMembers = agenda.members;

    return AgendaReady(agenda);
  }
}
