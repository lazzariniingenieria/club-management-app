import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/core/session/session_expiry_notifier.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:club_management_app/features/auth/domain/usecases/restore_session_use_case.dart';
import 'package:club_management_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:club_management_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:club_management_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockRestoreSessionUseCase extends Mock implements RestoreSessionUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

void main() {
  const storedAdmin = User(
    id: '1',
    email: 'admin@club.com',
    fullName: 'Ana Gómez',
    role: UserRole.admin,
  );

  late MockRestoreSessionUseCase restoreSession;
  late MockLogoutUseCase logout;
  late SessionExpiryNotifier expiryNotifier;

  AuthBloc buildBloc() => AuthBloc(
        restoreSession: restoreSession,
        logout: logout,
        sessionExpiryNotifier: expiryNotifier,
      );

  setUp(() {
    restoreSession = MockRestoreSessionUseCase();
    logout = MockLogoutUseCase();
    expiryNotifier = SessionExpiryNotifier();
    when(() => logout()).thenAnswer((_) async => const Right(null));
  });

  tearDown(() => expiryNotifier.dispose());

  test('starts without knowing whether there is a session', () {
    when(() => restoreSession()).thenAnswer((_) async => const Right(null));

    expect(buildBloc().state, const AuthSessionUnknown());
  });

  test('restores a stored session', () async {
    when(() => restoreSession())
        .thenAnswer((_) async => const Right(storedAdmin));
    final bloc = buildBloc();

    bloc.add(const AuthSessionRequested());

    await expectLater(
      bloc.stream,
      emits(const AuthAuthenticated(storedAdmin)),
    );
  });

  test('falls back to unauthenticated when there is nothing stored', () async {
    when(() => restoreSession()).thenAnswer((_) async => const Right(null));
    final bloc = buildBloc();

    bloc.add(const AuthSessionRequested());

    await expectLater(bloc.stream, emits(const AuthUnauthenticated()));
  });

  test('reports the session as unverified when restoring fails', () async {
    when(() => restoreSession())
        .thenAnswer((_) async => const Left(CacheFailure()));
    final bloc = buildBloc();

    bloc.add(const AuthSessionRequested());

    await expectLater(
      bloc.stream,
      emits(const AuthUnauthenticated(
          reason: SignedOutReason.sessionUnverified)),
    );
  });

  test('stops waiting for a session that never resolves', () async {
    when(() => restoreSession()).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 200),
        () => const Right(storedAdmin),
      ),
    );
    final bloc = AuthBloc(
      restoreSession: restoreSession,
      logout: logout,
      sessionExpiryNotifier: expiryNotifier,
      restoreTimeout: const Duration(milliseconds: 20),
    );

    bloc.add(const AuthSessionRequested());

    await expectLater(
      bloc.stream,
      emits(const AuthUnauthenticated(
          reason: SignedOutReason.sessionUnverified)),
    );
  });

  test('authenticates on login', () async {
    when(() => restoreSession()).thenAnswer((_) async => const Right(null));
    final bloc = buildBloc();

    bloc.add(const AuthLoggedIn(storedAdmin));

    await expectLater(bloc.stream, emits(const AuthAuthenticated(storedAdmin)));
  });

  test('clears the session on logout', () async {
    when(() => restoreSession()).thenAnswer((_) async => const Right(null));
    final bloc = buildBloc()..add(const AuthLoggedIn(storedAdmin));

    bloc.add(const AuthLogoutRequested());

    await expectLater(
      bloc.stream,
      emitsInOrder([
        const AuthAuthenticated(storedAdmin),
        const AuthUnauthenticated(),
      ]),
    );
    verify(() => logout()).called(1);
  });

  test('marks the session as expired when the interceptor reports a 401',
      () async {
    when(() => restoreSession()).thenAnswer((_) async => const Right(null));
    final bloc = buildBloc()..add(const AuthLoggedIn(storedAdmin));
    await bloc.stream.first;

    expiryNotifier.notifySessionExpired();

    await expectLater(
      bloc.stream,
      emits(const AuthUnauthenticated(reason: SignedOutReason.sessionExpired)),
    );
  });

  test('ignores an expiry report when nobody is signed in', () async {
    when(() => restoreSession()).thenAnswer((_) async => const Right(null));
    final bloc = buildBloc();

    expiryNotifier.notifySessionExpired();
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, const AuthSessionUnknown());
    verifyNever(() => logout());
  });
}
