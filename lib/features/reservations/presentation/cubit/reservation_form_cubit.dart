import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/load_day_agenda_use_case.dart';
import 'agenda_state.dart';

class ReservationFormCubit extends Cubit<AgendaState> {
  final LoadDayAgendaUseCase _loadAgenda;

  ReservationFormCubit(this._loadAgenda) : super(AgendaLoading(DateTime.now()));

  Future<void> showDay(DateTime day) async {
    emit(AgendaLoading(day));

    final result = await _loadAgenda(day);
    if (isClosed || state.day != day) return;

    emit(
      result.fold<AgendaState>(
        (failure) => AgendaFailure(day, isOffline: failure is NetworkFailure),
        AgendaReady.new,
      ),
    );
  }

  Future<void> reload() => showDay(state.day);
}
