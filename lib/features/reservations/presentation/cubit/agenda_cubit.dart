import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../courts/domain/usecases/watch_court_block_changes_use_case.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/usecases/cancel_reservation_use_case.dart';
import '../../domain/usecases/load_day_agenda_use_case.dart';
import '../../domain/usecases/watch_reservation_changes_use_case.dart';
import 'agenda_state.dart';

class AgendaCubit extends Cubit<AgendaState> {
  final LoadDayAgendaUseCase _loadAgenda;
  final CancelReservationUseCase _cancelReservation;
  late final List<StreamSubscription<void>> _changes;

  AgendaCubit({
    required LoadDayAgendaUseCase loadAgenda,
    required CancelReservationUseCase cancelReservation,
    required WatchReservationChangesUseCase watchReservations,
    required WatchCourtBlockChangesUseCase watchBlocks,
    DateTime Function() clock = DateTime.now,
  })  : _loadAgenda = loadAgenda,
        _cancelReservation = cancelReservation,
        super(AgendaLoading(_dayOf(clock()))) {
    _changes = [
      watchReservations().listen((_) => load()),
      watchBlocks().listen((_) => load()),
    ];
  }

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  Future<void> close() async {
    for (final subscription in _changes) {
      await subscription.cancel();
    }

    return super.close();
  }

  Future<void> load() => showDay(state.day);

  Future<void> showDay(DateTime day) async {
    final target = _dayOf(day);
    if (state is! AgendaReady || state.day != target) {
      emit(AgendaLoading(target));
    }

    final result = await _loadAgenda(target);
    if (isClosed || state.day != target) return;

    emit(
      result.fold<AgendaState>(
        (failure) =>
            AgendaFailure(target, isOffline: failure is NetworkFailure),
        AgendaReady.new,
      ),
    );
  }

  Future<Failure?> cancel(Reservation reservation) async {
    final result = await _cancelReservation(reservation.id);

    return result.getLeft().toNullable();
  }
}
