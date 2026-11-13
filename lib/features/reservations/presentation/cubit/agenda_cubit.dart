import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../courts/domain/usecases/watch_court_block_changes_use_case.dart';
import '../../../courts/domain/usecases/watch_court_changes_use_case.dart';
import '../../../members/domain/usecases/watch_roster_changes_use_case.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/usecases/cancel_reservation_use_case.dart';
import '../../domain/usecases/load_day_agenda_use_case.dart';
import '../../domain/usecases/watch_reservation_changes_use_case.dart';
import 'agenda_state.dart';
import 'day_agenda_loader.dart';

class AgendaCubit extends Cubit<AgendaState> with DayAgendaLoader {
  @override
  final LoadDayAgendaUseCase loadAgenda;
  final CancelReservationUseCase _cancelReservation;
  late final List<StreamSubscription<void>> _changes;

  AgendaCubit({
    required this.loadAgenda,
    required CancelReservationUseCase cancelReservation,
    required WatchReservationChangesUseCase watchReservations,
    required WatchCourtBlockChangesUseCase watchBlocks,
    required WatchCourtChangesUseCase watchCourts,
    required WatchRosterChangesUseCase watchRoster,
    DateTime Function() clock = DateTime.now,
  })  : _cancelReservation = cancelReservation,
        super(AgendaLoading(DayAgendaLoader.dayOf(clock()))) {
    _changes = [
      watchReservations().listen((_) => load()),
      watchBlocks().listen((_) => load()),
      watchCourts().listen((_) => load()),
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

  Future<Failure?> cancel(Reservation reservation) async {
    final result = await _cancelReservation(reservation.id);

    return result.getLeft().toNullable();
  }
}
