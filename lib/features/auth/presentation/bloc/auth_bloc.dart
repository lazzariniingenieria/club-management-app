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
  final Duration _restoreTimeout;

  late final StreamSubscription<void> _expirySubscription;

  AuthBloc({
    required RestoreSessionUseCase restoreSession,
    required LogoutUseCase logout,
    required SessionExpiryNotifier sessionExpiryNotifier,
    Duration restoreTimeout = defaultRestoreTimeout,
  })  : _restoreSession = restoreSession,
        _logout = logout,
        _restoreTimeout = restoreTimeout,
        super(const AuthSessionUnknown()) {
    on<AuthSessionRequested>(_onSessionRequested);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);

    _expirySubscription = sessionExpiryNotifier.onSessionExpired.listen(
      (_) => add(const AuthSessionExpired()),
    );
  }

  static const Duration defaultRestoreTimeout = Duration(seconds: 5);

  static const AuthState _sessionUnverified =
      AuthUnauthenticated(reason: SignedOutReason.sessionUnverified);

  Future<void> _onSessionRequested(
    AuthSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(await _resolvePersistedSession());
  }

  Future<AuthState> _resolvePersistedSession() async {
    try {
      final result = await _restoreSession().timeout(_restoreTimeout);

      return result.fold(
        (_) => _sessionUnverified,
        (user) =>
            user == null ? const AuthUnauthenticated() : AuthAuthenticated(user),
      );
    } on TimeoutException {
      return _sessionUnverified;
    }
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
    emit(const AuthUnauthenticated(reason: SignedOutReason.sessionExpired));
  }

  @override
  Future<void> close() {
    _expirySubscription.cancel();
    return super.close();
  }
}
