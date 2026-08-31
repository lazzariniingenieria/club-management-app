import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthSessionUnknown extends AuthState {
  const AuthSessionUnknown();
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  final bool sessionExpired;

  const AuthUnauthenticated({this.sessionExpired = false});

  @override
  List<Object?> get props => [sessionExpired];
}
