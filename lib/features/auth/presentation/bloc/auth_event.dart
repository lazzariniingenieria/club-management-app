import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSessionRequested extends AuthEvent {
  const AuthSessionRequested();
}

class AuthLoggedIn extends AuthEvent {
  final User user;

  const AuthLoggedIn(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
