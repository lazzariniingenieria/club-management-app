import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../club/domain/usecases/load_club_use_case.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/usecases/watch_roster_changes_use_case.dart';
import '../../domain/entities/day_agenda.dart';
import '../../domain/usecases/load_day_agenda_use_case.dart';
import '../../domain/usecases/watch_reservation_changes_use_case.dart';

sealed class UpcomingReservationsState extends Equatable {
  const UpcomingReservationsState();

  @override
  List<Object?> get props => [];
}

class UpcomingReservationsHidden extends UpcomingReservationsState {
  const UpcomingReservationsHidden();
}

class UpcomingReservationsLoading extends UpcomingReservationsState {
  const UpcomingReservationsLoading();
}

class UpcomingReservationsReady extends UpcomingReservationsState {
  final DayAgenda agenda;
  final List<UpcomingReservation> upcoming;

  const UpcomingReservationsReady({
    required this.agenda,
    required this.upcoming,
  });

  @override
  List<Object?> get props => [agenda, upcoming];
}

class UpcomingReservationsFailure extends UpcomingReservationsState {
  final bool isOffline;

  const UpcomingReservationsFailure({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}

class UpcomingReservationsCubit extends Cubit<UpcomingReservationsState> {
  final LoadClubUseCase _loadClub;
  final LoadDayAgendaUseCase _loadAgenda;
  final DateTime Function() _clock;
  late final List<StreamSubscription<void>> _changes;
  List<Member>? _knownMembers;

  static const int shownReservations = 3;

  UpcomingReservationsCubit({
    required LoadClubUseCase loadClub,
    required LoadDayAgendaUseCase loadAgenda,
    required WatchReservationChangesUseCase watchReservations,
    required WatchRosterChangesUseCase watchRoster,
    DateTime Function() clock = DateTime.now,
  })  : _loadClub = loadClub,
        _loadAgenda = loadAgenda,
        _clock = clock,
        super(const UpcomingReservationsHidden()) {
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

  Future<void> refresh() {
    _knownMembers = null;

    return load();
  }

  Future<void> load() async {
    final club = await _loadClub();
    if (isClosed) return;
    if (!club.fold((_) => false, (club) => club.courtsEnabled)) {
      emit(const UpcomingReservationsHidden());
      return;
    }

    if (state is! UpcomingReservationsReady) {
      emit(const UpcomingReservationsLoading());
    }
    final now = _clock();
    final agenda = await _loadAgenda(
      DateTime(now.year, now.month, now.day),
      knownMembers: _knownMembers,
    );
    if (isClosed) return;
    _knownMembers = agenda.getRight().toNullable()?.members ?? _knownMembers;

    emit(agenda.fold(_failureOf, (agenda) => _readyOf(agenda, now)));
  }

  static UpcomingReservationsState _failureOf(Failure failure) =>
      UpcomingReservationsFailure(isOffline: failure is NetworkFailure);

  static UpcomingReservationsState _readyOf(DayAgenda agenda, DateTime now) =>
      UpcomingReservationsReady(
        agenda: agenda,
        upcoming: agenda.upcoming(now, limit: shownReservations),
      );
}
