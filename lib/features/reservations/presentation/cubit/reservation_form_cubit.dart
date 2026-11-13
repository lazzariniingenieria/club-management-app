import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../members/domain/usecases/watch_roster_changes_use_case.dart';
import '../../domain/usecases/load_day_agenda_use_case.dart';
import '../../domain/usecases/watch_reservation_changes_use_case.dart';
import 'agenda_state.dart';
import 'day_agenda_loader.dart';

class ReservationFormCubit extends Cubit<AgendaState> with DayAgendaLoader {
  @override
  final LoadDayAgendaUseCase loadAgenda;
  late final List<StreamSubscription<void>> _changes;

  ReservationFormCubit({
    required this.loadAgenda,
    required WatchReservationChangesUseCase watchReservations,
    required WatchRosterChangesUseCase watchRoster,
  }) : super(AgendaLoading(DayAgendaLoader.dayOf(DateTime.now()))) {
    _changes = [
      watchReservations().listen((_) => load()),
      watchRoster().listen((_) => refresh()),
    ];
  }

  @override
  Future<void> close() async {
    for (final subscription in _changes) {
      await subscription.cancel();
    }

    return super.close();
  }
}
