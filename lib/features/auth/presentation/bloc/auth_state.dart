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

enum SignedOutReason { signedOut, sessionExpired, sessionUnverified }

class AuthUnauthenticated extends AuthState {
  final SignedOutReason reason;

  const AuthUnauthenticated({this.reason = SignedOutReason.signedOut});

  bool get sessionExpired => reason == SignedOutReason.sessionExpired;

  bool get sessionUnverified => reason == SignedOutReason.sessionUnverified;

  @override
  List<Object?> get props => [reason];
}
