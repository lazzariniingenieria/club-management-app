import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_summary.dart';

sealed class AdminHomeState extends Equatable {
  const AdminHomeState();

  @override
  List<Object?> get props => [];
}

class AdminHomeLoading extends AdminHomeState {
  const AdminHomeLoading();
}

class AdminHomeReady extends AdminHomeState {
  final AdminSummary summary;

  const AdminHomeReady(this.summary);

  @override
  List<Object?> get props => [summary];
}

class AdminHomeFailure extends AdminHomeState {
  final String message;

  const AdminHomeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
