import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/session_expiry_notifier.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/restore_session_use_case.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RestoreSessionUseCase _restoreSession;
  final LogoutUseCase _logout;

  late final StreamSubscription<void> _expirySubscription;

  AuthBloc({
    required RestoreSessionUseCase restoreSession,
    required LogoutUseCase logout,
    required SessionExpiryNotifier sessionExpiryNotifier,
  })  : _restoreSession = restoreSession,
        _logout = logout,
        super(const AuthSessionUnknown()) {
    on<AuthSessionRequested>(_onSessionRequested);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);

    _expirySubscription = sessionExpiryNotifier.onSessionExpired.listen(
      (_) => add(const AuthSessionExpired()),
    );
  }

  Future<void> _onSessionRequested(
    AuthSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _restoreSession();

    emit(
      result.fold(
        (_) => const AuthUnauthenticated(),
        (user) => user == null
            ? const AuthUnauthenticated()
            : AuthAuthenticated(user),
      ),
    );
  }

  void _onLoggedIn(AuthLoggedIn event, Emitter<AuthState> emit) {
    emit(AuthAuthenticated(event.user));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;

    await _logout();
    emit(const AuthUnauthenticated(sessionExpired: true));
  }

  @override
  Future<void> close() {
    _expirySubscription.cancel();
    return super.close();
  }
}
