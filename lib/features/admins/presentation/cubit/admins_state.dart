import 'package:equatable/equatable.dart';

import '../../domain/entities/admins_overview.dart';

sealed class AdminsState extends Equatable {
  const AdminsState();

  @override
  List<Object?> get props => [];
}

class AdminsLoading extends AdminsState {
  const AdminsLoading();
}

class AdminsReady extends AdminsState {
  final AdminsOverview overview;

  const AdminsReady(this.overview);

  @override
  List<Object?> get props => [overview];
}

class AdminsFailure extends AdminsState {
  final bool isOffline;

  const AdminsFailure({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}
