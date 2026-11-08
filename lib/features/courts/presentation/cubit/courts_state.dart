import 'package:equatable/equatable.dart';

import '../../domain/entities/court.dart';

sealed class CourtsState extends Equatable {
  const CourtsState();

  @override
  List<Object?> get props => [];
}

class CourtsLoading extends CourtsState {
  const CourtsLoading();
}

class CourtsReady extends CourtsState {
  final List<Court> courts;

  const CourtsReady(this.courts);

  @override
  List<Object?> get props => [courts];
}

class CourtsFailure extends CourtsState {
  final bool isOffline;

  const CourtsFailure({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}
