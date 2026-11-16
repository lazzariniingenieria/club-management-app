import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../club/domain/usecases/load_club_use_case.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/usecases/watch_roster_changes_use_case.dart';
import '../../domain/usecases/load_upcoming_reservations_use_case.dart';
import '../../domain/usecases/watch_reservation_changes_use_case.dart';
import 'upcoming_reservations_state.dart';

class UpcomingReservationsCubit extends Cubit<UpcomingReservationsState> {
  final LoadClubUseCase _loadClub;
  final LoadUpcomingReservationsUseCase _loadUpcoming;
  final DateTime Function() _clock;
  late final List<StreamSubscription<void>> _changes;
  List<Member>? _knownMembers;

  static const int shownReservations = 3;

  UpcomingReservationsCubit({
    required LoadClubUseCase loadClub,
    required LoadUpcomingReservationsUseCase loadUpcoming,
    required WatchReservationChangesUseCase watchReservations,
    required WatchRosterChangesUseCase watchRoster,
    DateTime Function() clock = DateTime.now,
  })  : _loadClub = loadClub,
        _loadUpcoming = loadUpcoming,
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
    final upcoming = await _loadUpcoming(
      _clock(),
      limit: shownReservations,
      knownMembers: _knownMembers,
    );
    if (isClosed) return;
    _knownMembers = upcoming.getRight().toNullable()?.roster ?? _knownMembers;

    emit(upcoming.fold(_failureOf, UpcomingReservationsReady.new));
  }

  static UpcomingReservationsState _failureOf(Failure failure) =>
      UpcomingReservationsFailure(isOffline: failure is NetworkFailure);
}
