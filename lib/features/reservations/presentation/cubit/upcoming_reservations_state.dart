import 'package:equatable/equatable.dart';

import '../../domain/entities/upcoming_reservations.dart';

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
  final UpcomingReservations upcoming;

  const UpcomingReservationsReady(this.upcoming);

  @override
  List<Object?> get props => [upcoming];
}

class UpcomingReservationsFailure extends UpcomingReservationsState {
  final bool isOffline;

  const UpcomingReservationsFailure({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}
